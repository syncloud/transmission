SERVICES = ['daemon', 'nginx']


def assert_no_restarts(device):
    for service in SERVICES:
        unit = 'snap.transmission.{0}.service'.format(service)
        restarts = device.run_ssh('systemctl show -p NRestarts --value {0}'.format(unit))
        assert restarts.strip() == '0', '{0} restarted {1} times'.format(unit, restarts.strip())
