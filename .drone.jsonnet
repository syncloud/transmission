local name = 'transmission';
local version = '4.0.5';
local nginx = '1.24.0';
local platform = '26.08.01';
local playwright = 'mcr.microsoft.com/playwright:v1.59.1-jammy';
local store_publisher = 'stable-346';
local python = '3.12-slim-bookworm';
local distro_default = 'buster';
local distros = ['bookworm', 'buster'];

local platform_image(distro) =
  'syncloud/platform-' + distro + ':' + platform;

local build(arch, test_ui) = [{
  kind: 'pipeline',
  type: 'docker',
  name: arch,
  platform: {
    os: 'linux',
    arch: arch,
  },
  steps: [
    {
      name: 'nginx',
      image: 'nginx:' + nginx,
      commands: [
        './nginx/build.sh',
      ],
    },
    {
      name: 'nginx test',
      image: platform_image(distro_default),
      commands: [
        './nginx/test.sh',
      ],
    },
    {
      name: 'transmission',
      image: 'debian:bookworm-slim',
      commands: [
        './transmission/build.sh ' + version + ' ' + arch,
      ],
    },
    {
      name: 'test transmission',
      image: 'debian:bookworm-slim',
      commands: [
        './transmission/test.sh',
      ],
    },
    {
      name: 'cli',
      image: 'golang:1.20',
      commands: [
        'cd cli',
        "go build -ldflags '-linkmode external -extldflags -static' -o ../build/snap/meta/hooks/install ./cmd/install",
        "go build -ldflags '-linkmode external -extldflags -static' -o ../build/snap/meta/hooks/configure ./cmd/configure",
        "go build -ldflags '-linkmode external -extldflags -static' -o ../build/snap/meta/hooks/pre-refresh ./cmd/pre-refresh",
        "go build -ldflags '-linkmode external -extldflags -static' -o ../build/snap/meta/hooks/post-refresh ./cmd/post-refresh",
        "go build -ldflags '-linkmode external -extldflags -static' -o ../build/snap/bin/cli ./cmd/cli",
      ],
    },
    {
      name: 'package',
      image: 'debian:bookworm-slim',
      commands: [
        './package.sh ' + name + ' $DRONE_BUILD_NUMBER',
      ],
    },
  ] + [
    {
      name: 'test ' + distro,
      image: 'python:' + python,
      commands: [
        'DOMAIN="' + distro + '.com"',
        'APP_DOMAIN="' + name + '.' + distro + '.com"',
        'getent hosts $APP_DOMAIN | sed "s/$APP_DOMAIN/auth.$DOMAIN/g" | tee -a /etc/hosts',
        'cat /etc/hosts',
        'APP_ARCHIVE_PATH=$(realpath $(cat package.name))',
        'cd test',
        './deps.sh',
        'py.test -x -s test.py --distro=' + distro + ' --domain=' + distro + '.com --app-archive-path=$APP_ARCHIVE_PATH --device-host=' + name + '.' + distro + '.com --app=' + name + ' --arch=' + arch,
      ],
    }
    for distro in distros
  ] + (if test_ui then [
         {
           name: 'e2e',
           image: playwright,
           commands: [
             './test/e2e/run.sh e2e specs/01-login.spec.ts',
           ],
         },
         {
           name: 'e2e-mobile',
           image: playwright,
           commands: [
             './test/e2e/run.sh e2e-mobile specs/01-login.spec.ts mobile',
           ],
         },
       ] else []) + [
    {
      name: 'test-upgrade',
      image: 'python:' + python,
      commands: [
        'DOMAIN="' + distro_default + '.com"',
        'APP_DOMAIN="' + name + '.' + distro_default + '.com"',
        'getent hosts $APP_DOMAIN | sed "s/$APP_DOMAIN/auth.$DOMAIN/g" | tee -a /etc/hosts',
        'cat /etc/hosts',
        'APP_ARCHIVE_PATH=$(realpath $(cat package.name))',
        'cd test',
        './deps.sh',
        'py.test -x -s upgrade.py --distro=buster --domain=buster.com --app-archive-path=$APP_ARCHIVE_PATH --device-host=' + name + '.buster.com --app=' + name,
      ],
    },
    {
      name: 'publish',
      image: 'syncloud/store-publisher:' + store_publisher,
      environment: {
        SYNCLOUD_TOKEN: { from_secret: 'SYNCLOUD_TOKEN' },
      },
      command: ['snap', '-c', '${DRONE_BRANCH}'],
      when: {
        branch: ['master', 'stable'],
        event: ['push'],
      },
    },
    {
      name: 'artifact',
      image: 'appleboy/drone-scp:1.6.4',
      settings: {
        host: {
          from_secret: 'artifact_host',
        },
        username: 'artifact',
        key: {
          from_secret: 'artifact_key',
        },
        timeout: '2m',
        command_timeout: '2m',
        target: '/home/artifact/repo/' + name + '/${DRONE_BUILD_NUMBER}-' + arch,
        source: 'artifact/*',
        strip_components: 1,
      },
      when: {
        status: ['failure', 'success'],
        event: ['push'],
      },
    },
  ],
  trigger: {
    event: ['push'],
  },
  services: [
    {
      name: name + '.' + distro + '.com',
      image: platform_image(distro),
      privileged: true,
      entrypoint: ['/bin/sh', '-c', "mkdir -p /etc/systemd/system/snapd.service.d && printf '[Service]\\nExecStartPost=/bin/sh -c \"/usr/bin/snap set system refresh.hold=2099-01-01T00:00:00Z\"\\n' > /etc/systemd/system/snapd.service.d/disable-refresh.conf && exec /sbin/init"],
      volumes: [
        {
          name: 'dbus',
          path: '/var/run/dbus',
        },
        {
          name: 'dev',
          path: '/dev',
        },
      ],
    }
    for distro in distros
  ],
  volumes: [
    {
      name: 'dbus',
      host: {
        path: '/var/run/dbus',
      },
    },
    {
      name: 'dev',
      host: {
        path: '/dev',
      },
    },
  ],
}];

build('amd64', true) +
build('arm64', false) +
build('arm', false)
