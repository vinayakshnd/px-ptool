import yaml
import sys


cloud = sys.argv[1]
outfile = '{}/terraform.tfvars'.format(cloud)

with open('config.yaml', mode='r') as f:
    ycfg = yaml.load(f)

if cloud not in ycfg.keys():
    raise RuntimeError("ERROR : Cloud %s is not supported", cloud)

with open(outfile,mode='w') as ofile:
    for k,v in ycfg[cloud].items():
        #print "Value is {} type is {}".format(v, type(v))
        if type(v) is int:
            ofile.write("{} = {}\n".format(k,v))
        else:
            ofile.write("{} = \"{}\"\n".format(k,v))

