# Attempt to import additional MODIS data from Earth Engine

import csv
import ee
import datetime

ee.Initialize()

locs=[]
with open('data/locs.csv') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        locs.append(row)


modis_evi = ee.ImageCollection('MODIS/MYD09GA_EVI')
# modis_ndwi = ee.ImageCollection('MODIS/MYD09GA_NDWI')

def getPixelValue(image, point, band):
    evi_value = image.reduceRegion(
        reducer=ee.Reducer.mean(),
        geometry=point,
        # idk what to put for scale & max pixels. It probably shouldn't matter?
        scale=250,
        maxPixels=9
    )
    # Crappy hack to grab date info: It's most obviously stored in the system index.
    # Parse it later.
    # TODO: What is being returned as system:time_end and system:time_start??? Handle as real dates?
    dict = {}
    dict['index'] = image.getInfo()['properties']['system:index']
    dict[band] = evi_value.getInfo()[band]
    return dict


## So this works, but ee appears to handle network errors by hanging, rather than
## throwing an exception.
## Needs to be restructured for MOAR ROBUST WOW.

datas = []
i = 0
for loc in locs:
    point = ee.Geometry.Point(float(loc['Latitude']), float(loc['Longitude']))

    # Create date filters
    date = datetime.datetime.strptime(loc['ObsDate'], "%Y-%m-%d").date()
    interval = datetime.timedelta(days=-14)

    end = date.strftime("%Y-%m-%d")
    start = (date + interval).strftime("%Y-%m-%d")

    evi = modis_evi.filterDate(start, end).filterBounds(point)
#    ndwi = modis_ndwi.filterDate(start, end).filterBounds(point)

    # We want "datas" to be a list of dictionaries - each
    # has 'location.ID', 'index' (system index/date), 'NDWI' or 'EVI' key/val pairs 
    
    # Brute force iteration over image collections!
    # TODO? restructure what I'm doing to pass to map()
    for e in evi.getInfo()['features']:
        image_id = e['id']
        image = ee.Image(image_id)

        vals = getPixelValue(image, point, 'EVI')
        vals['Location.ID'] = loc['Location.ID']
        datas.append(vals)
#
#    for n in ndwi.getInfo()['features']:
#        image_id = n['id']
#        image = ee.Image(image_id)
#
#        vals = getPixelValue(image, point, 'NDWI')
#        vals['Location.ID'] = loc['Location.ID']
#        datas.append(vals)

    print("Finished row {0}\n".format(i))
    i += 1

    # Write datas as csv
    # (Deliberately inside the for loop, to make sure data is captured)
    keys = ['Location.ID', 'index', 'EVI', 'NDWI']
    with open('modis_daily_data.csv', 'wb') as output:
        dict_writer = csv.DictWriter(output, keys)
        dict_writer.writeheader()
        dict_writer.writerows(datas)
