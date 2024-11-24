
import xarray as xr 

folder = "/global/scratch/users/leoal/test_convert/convert/output"
file = '2018110811'

# BKG_FILE=${BKG_ROOT}/wrfinput_d01_${date}.nc
fp = "%s/wrfinput_d01_%s.nc" % (folder, file)

data = xr.open_dataset(fp)

print(data)