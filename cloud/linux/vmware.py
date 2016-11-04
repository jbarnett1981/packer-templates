#!/usr/bin/python
'''
Created `10/16/2015 09:49`

@author jbarnett@tableau.com
@version 0.1

vmware.py: Finds an orphaned vm in a specific folder, returns its UUID,
destroys it and then adds the new VMX to the inventory as a template.

TODO:
1. check for existing template of the same name before creating new template, and if exist, move to -OLD
'''

from pyVim.connect import SmartConnect, Disconnect
from pyVmomi import vim
import time
import sys
import os
import json
import datetime
import math
import __builtin__
import logging
import random

def get_uuid(vmfolder, vmname, vmstatus):
    '''
    Get UUID of specific orphaned vm from vmfolder
    '''

    # if this is a group it will have children, if so iterate through all the VMs in said parent
    if hasattr(vmfolder, 'childEntity'):
        vmlist = vmfolder.childEntity
        for vm in vmlist:
            summary = vm.summary
            if summary.config.name == vmname and summary.runtime.connectionState == vmstatus:
                return summary.config.instanceUuid

def vmware_create(flavor):
    '''
    Main code block
    '''

    # Setup logging
    logger = logging.getLogger('build_log.vmware_create')

    # Date stuff
    current_date = datetime.datetime.now()
    date_suffix = current_date.strftime('%Y-%m-%d')
    current_year = current_date.strftime('%Y')
    current_quarter = int(math.ceil(current_date.month/3.))
    quarter_string = '{0}Q{1}'.format(current_year, current_quarter)

    config_file = '/'.join([os.getcwd(), 'vmware', 'vsphere_creds.json'])
    data = json.loads(open(config_file).read())
    host = data['creds']['vmware']['host']
    port = int(data['creds']['vmware']['port'])
    user = data['creds']['vmware']['user']
    password = data['creds']['vmware']['password']
    datastore = data['creds']['vmware']['datastore']
    packer_template = '/'.join([os.getcwd(), '%s-x64-vmware.json' % flavor])
    image_path_base = 'packer_images/%s-vmware-%s/devit-%s-vmware-%s.vmx' % (flavor, date_suffix, flavor, date_suffix)

    #hacky workaround to ssl cert warnings in Python 2.7.9+
    #http://www.errr-online.com/index.php/tag/pyvmomi/
    import requests, ssl
    requests.packages.urllib3.disable_warnings()
    try:
        _create_unverified_https_context = ssl._create_unverified_context
    except AttributeError:
        pass
    else:
        ssl._create_default_https_context = _create_unverified_https_context

    # Make connection to vcenter
    try:
        si = SmartConnect(host=host, user=user, pwd=password, port=port)
        logger.info("Connected to %s" % host)

    except IOError, e:
        pass

    if not si:
        logger.info("Could not connect to the specified host using specified username and password")

    # Get vcenter content object
    content = si.RetrieveContent()

    # Get list of DCs in vCenter and set datacente to the vim.Datacenter object corresponding to the "Internap" DC
    datacenters = content.rootFolder.childEntity
    for dc in datacenters:
        if dc.name == "Internap":
            datacenter = dc

    # Get List of Folders in the "Internap" DC and set tfolder to the vim.Folder object corresponding to the "Templates" folder
    dcfolders = datacenter.vmFolder
    vmfolders = dcfolders.childEntity
    for folder in vmfolders:
        if folder.name == "Templates":
            tfolder = folder
        # Set "Discovered virtual machine" folder to orphan_folder for future use.
        elif folder.name == "Discovered virtual machine":
            orphan_folder = folder

    # Get List of Hosts in DevIT-Internap cluster
    object_view = content.viewManager.CreateContainerView(content.rootFolder, [vim.HostSystem], True)
    host_list = object_view.view
    hosts = []
    for host in host_list:
        if host.parent.name == 'DevIT-Internap':
            hosts.append(host.name)
    template_host = random.choice(hosts)

    # Get vim.HostSystem object for specific ESX host to place template on
    esxhost = content.searchIndex.FindByDnsName(None, template_host, vmSearch=False)

    # Wait 30 seconds for vCenter to detect orphaned VM, before attempting to delete.
    time.sleep(30)

    # Clean up orphaned VM from packer build since they don't do it. BUG submitted https://github.com/mitchellh/packer/issues/2841
    orphan_uuid = get_uuid(orphan_folder, "devit-%s-vmware-%s" % (flavor, date_suffix), "orphaned")
    if orphan_uuid is not None:
        vm = content.searchIndex.FindByUuid(None, orphan_uuid, True, True)
        logger.info("Deleting orphan vm: %s" % vm.summary.config.name)
        vm.Destroy_Task()

        # Wait 10 seconds until VMWare updates that the orphaned item has been deleted before trying to create a new one
        logger.info("Waiting 10s for vCenter to register successful orphan deletion")
        time.sleep(10)

        # Wow, we can actually do stuff now! Add the VMX in the specified path to the inventory as a template within the "Templates" folder
        logger.info("Adding new image to inventory as a template")
        tfolder.RegisterVM_Task(datastore + ' ' + image_path_base, "Template %s - %s" % (flavor, quarter_string), asTemplate=True, host=esxhost)
        logger.info("Done!")

if __name__ == "__main__":
    try:
       sys.argv[1]
    except IndexError:
       sys.exit("Please specify flavor (centos7, ubuntu1404, ubuntu1604)")
    flavor = sys.argv[1]
    vmware_create(flavor)