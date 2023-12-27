import pytest
from os.path import dirname, join
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from subprocess import check_output
from syncloudlib.integration.hosts import add_host_alias
from selenium.webdriver.support import expected_conditions as EC

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud/ui'


@pytest.fixture(scope="session")
def module_setup(request, device, artifact_dir, ui_mode):
    def module_teardown():
        device.activated()
        device.run_ssh('mkdir -p {0}'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl > {0}/journalctl.ui.{1}.log'.format(TMP_DIR, ui_mode), throw=False)
        device.scp_from_device('{0}/*'.format(TMP_DIR), join(artifact_dir, 'log'))
        check_output('cp /videos/* {0}'.format(artifact_dir), shell=True)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(module_teardown)


def test_start(module_setup, app, domain, device_host):
    add_host_alias(app, device_host, domain)


def test_login(selenium, device_user, device_password):
    selenium.open_app()
    selenium.find_by(By.ID, "username-textfield").send_keys(device_user)
    password = selenium.find_by(By.ID, "password-textfield")
    password.send_keys(device_password)
    selenium.screenshot('login')
    #password.send_keys(Keys.RETURN)
    selenium.find_by(By.ID, "sign-in-button").click()
    selenium.find_by(By.XPATH, "//div[@title='Tramsmission']")
    selenium.screenshot('main')


def test_upload(selenium):
    selenium.screenshot('upload')
    selenium.find_by(By.XPATH, "//button[@title='Upload']").click()
    file = selenium.driver.find_element(By.XPATH, "//input[@type='file']")
    selenium.driver.execute_script("arguments[0].removeAttribute('class')", file)
    file.send_keys(join(DIR, 'images', 'profile.jpeg'))
    # selenium.find_by(By.XPATH, "//form//span[text()='Upload']").click()
    selenium.screenshot('uploaded')
    selenium.wait_or_screenshot(EC.invisibility_of_element_located((By.XPATH, "//nav//span[text()='Upload']")))


def test_folders(selenium):
    selenium.find_by(By.XPATH, "//div[@title='Folders']").click()
    selenium.exists_by(By.XPATH, "//a[contains(@class,'result')]")
    selenium.screenshot('folders')


def test_teardown(driver):
    driver.quit()
