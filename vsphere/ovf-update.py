#!/usr/bin/python

from lxml import etree as ET
import re
import sys

input = sys.argv[1]

ET.register_namespace("ovf", "http://schemas.dmtf.org/ovf/envelope/1")
tree = ET.parse(input)

root = tree.getroot()

# define ns
rasd = '{http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData}'
vmw = '{http://www.vmware.com/schema/ovf}'
ns = re.match(r'{.*}', root.tag).group(0)

# Update initial network entry
network = root.find(f"{ns}NetworkSection")
for child in network:
    if child.tag == f"{ns}Network":
        child.attrib[f"{ns}name"] = "Management"
    for subchild in child:
        if subchild.tag == f"{ns}Description":
            subchild.text = "The Management network"

# add storage network to NetworkSection
for child in root:
    if child.tag == f"{ns}NetworkSection":
        s = ET.SubElement(child, f"{ns}Network")
        s.attrib[f"{ns}name"] = "Storage"
        t = ET.SubElement(s, f"{ns}Description")
        t.text = "The Storage network"

# update network adapters with correct name and description
for item in root.iter(f"{ns}Item"):
    for tag in item.findall(f"{rasd}ElementName"):
        if tag.text == "Network adapter 1":
            desc = item.findall(f"{rasd}Description")
            desc[0].text = "The Management network"
            conn = item.findall(f"{rasd}Connection")
            conn[0].text = "Management"
        if tag.text == "Network adapter 2":
            desc = item.findall(f"{rasd}Description")
            desc[0].text = "The Storage network"
            conn = item.findall(f"{rasd}Connection")
            conn[0].text = "Storage"

# write output
tree.write(input,
           xml_declaration=True, encoding='utf-8', method="xml", pretty_print=True)
