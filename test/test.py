import os
from os.path import join
from subprocess import check_output

import pytest
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
from retrying import retry
from syncloudlib.http import wait_for_rest
from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.integration.installer import local_install
from test import snapd
from test.services import assert_no_restarts

TMP_DIR = '/tmp/syncloud'
DATA_DIR = '/var/snap/transmission/current'
COMMON_DIR = '/var/snap/transmission/common'

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)


@pytest.fixture(scope="session")
def module_setup(request, device, app_dir, artifact_dir):
    def module_teardown():
        device.run_ssh('mkdir -p {0}'.format(TMP_DIR), throw=False)
        device.run_ssh('cp {0}/config/settings.json {1}/settings.json.log'.format(DATA_DIR, TMP_DIR), throw=False)
        device.run_ssh('top -bn 1 -w 500 -c > {0}/top.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ps auxfw > {0}/ps.log'.format(TMP_DIR), throw=False)
        device.run_ssh('netstat -nlp > {0}/netstat.log'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl > {0}/journalctl.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la {0}/ > {1}/app.ls.log'.format(app_dir, TMP_DIR), throw=False)
        device.run_ssh('ls -laR {0}/ > {1}/data.ls.log'.format(DATA_DIR, TMP_DIR), throw=False)
        device.run_ssh('ls -laR {0}/ > {1}/common.ls.log'.format(COMMON_DIR, TMP_DIR), throw=False)
        device.run_ssh('ls -la /data/transmission > {0}/storage.ls.log'.format(TMP_DIR), throw=False)
        app_log_dir = join(artifact_dir, 'log')
        os.mkdir(app_log_dir)
        device.scp_from_device('{0}/*'.format(TMP_DIR), app_log_dir)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(module_teardown)


def test_start(module_setup, device, device_host, app, domain):
    add_host_alias(app, device_host, domain)
    device.run_ssh('date', retries=100)
    snapd.settle(device)
    device.run_ssh('mkdir -p {0}'.format(TMP_DIR))


@pytest.mark.flaky(retries=50, delay=10)
def test_activate_device(device):
    response = device.activate_custom()
    assert response.status_code == 200, response.text


def test_install(app_archive_path, device_host, device_password):
    local_install(device_host, device_password, app_archive_path)


def test_index(app_domain):
    wait_for_rest(requests.session(), "https://{0}".format(app_domain), 200, 10)


def test_rpc_socket(device):
    socket = device.run_ssh('stat -c %F {0}/transmission.socket'.format(DATA_DIR), retries=100)
    assert socket.splitlines() == ['socket'], socket


def test_web_requires_auth(app_domain):
    r = requests.get('https://{0}/transmission/web/'.format(app_domain), verify=False, allow_redirects=False)
    assert r.status_code in (301, 302, 303), r.status_code
    assert 'auth.' in r.headers.get('Location', ''), r.headers.get('Location')


def test_settings_seeded(device):
    settings = device.run_ssh('cat {0}/config/settings.json'.format(DATA_DIR))
    assert 'transmission.socket' in settings, settings


def test_download_dir(device):
    types = device.run_ssh('stat -c %F /data/transmission/download')
    assert types.splitlines() == ['directory'], types


def test_storage_change_event(device):
    device.run_ssh('snap run transmission.storage-change > {0}/storage-change.log'.format(TMP_DIR))


def test_access_change_event(device):
    device.run_ssh('snap run transmission.access-change > {0}/access-change.log'.format(TMP_DIR))


@retry(stop_max_attempt_number=30, wait_fixed=2000)
def assert_web_ui(device, marker):
    index = device.run_ssh('curl -sf --unix-socket {0}/transmission.socket http://localhost/transmission/web/'.format(DATA_DIR))
    assert marker in index, index


def test_web_ui_default(device):
    assert device.run_ssh('snap run transmission.cli web-ui').strip().splitlines()[-1] == 'default'
    assert_web_ui(device, 'favicon.svg')


def test_web_ui_legacy(device):
    device.run_ssh('snap run transmission.cli web-ui legacy > {0}/web-ui-legacy.log 2>&1'.format(TMP_DIR))
    assert device.run_ssh('snap run transmission.cli web-ui').strip().splitlines()[-1] == 'legacy'
    assert_web_ui(device, 'webclip-icon.png')


def test_web_ui_back_to_default(device):
    device.run_ssh('snap run transmission.cli web-ui default > {0}/web-ui-default.log 2>&1'.format(TMP_DIR))
    assert device.run_ssh('snap run transmission.cli web-ui').strip().splitlines()[-1] == 'default'
    assert_web_ui(device, 'favicon.svg')


def test_services_started_cleanly(device):
    assert_no_restarts(device)


def test_remove(device, app):
    response = device.app_remove(app)
    assert response.status_code == 200, response.text


def test_reinstall(app_archive_path, device_host, device_password, device):
    local_install(device_host, device_password, app_archive_path)
    device.run_ssh('stat -c %F {0}/transmission.socket'.format(DATA_DIR), retries=100)
    assert_no_restarts(device)


def test_refresh(app_archive_path, device_host, device_password, app_domain, device):
    local_install(device_host, device_password, app_archive_path)
    wait_for_rest(requests.session(), "https://{0}".format(app_domain), 200, 10)
    assert_no_restarts(device)
