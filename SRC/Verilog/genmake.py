import  xml.etree.ElementTree as ET
import os, sys, glob

if __name__=='__main__':
    files = sorted(glob.glob('*.xise'), key=os.path.getmtime, reverse=True)
    if not len(files):
        os.exit()
    file = files[0]
    print(file)
    tree =  ET.parse(file)
    root = tree.getroot()
    tag = '{' + root.tag.split('}')[0][1:] + '}'
    files = root.find(f'{tag}files').findall(f'{tag}file')
    vfiles = []
    for file in files:
        _name = file.attrib[f'{tag}name']
        _type = file.attrib[f'{tag}type']
        if _type == 'FILE_UCF':
            open('ucf_file','w').write(_name+'\n')
        elif _type == 'FILE_VERILOG':
            print(_name)
            vfiles.append(_name)
    if len(vfiles):
        open('verilog_files','w').write('\n'.join(vfiles))
        