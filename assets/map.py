from PIL import Image

TILE_SIZE = 8
tile_no = 0

tiles = {}

tile_file = open("tiles.inc", "w")
map_file = open("map.inc", "w")
#return_file = open("return.inc", "w")

def tilePrint(x: int, y: int, pix: any):
    pr = ""
    for i in range(TILE_SIZE):
        for j in range(TILE_SIZE):
            pr += str(pix[x + j, y + i])
    return pr

def outputTileRow(pr: str):
    tile_file.write('\t\tdc.b\t%' + pr.replace('2', '0') + ',%0\n')
    tile_file.write('\t\tdc.b\t%' + pr.replace('1', '0').replace('2', '1') + ',%0\n')
    tile_file.write('\t\tds.b\t4' + '\n')

def outputTile(pr: str):
    outputTileRow(pr[0:8])
    outputTileRow(pr[8:16])
    outputTileRow(pr[16:24])
    outputTileRow(pr[24:32])
    outputTileRow(pr[32:40])
    outputTileRow(pr[40:48])
    outputTileRow(pr[48:56])
    outputTileRow(pr[56:64])

# see if we know this tile
def getTile(x: int, y: int, pix: any):
    global tile_no
    pr = tilePrint(x, y, pix)
    if not pr in tiles:
        tiles[pr] = tile_no
        outputTile(pr)
        tile_no = tile_no + 1
    return tiles[pr]

print('Hello')
im = Image.open("map.png")
pix = im.load()

# pregenerate key tiles
getTile(0, 80, pix) # blank
getTile(8, 8, pix) # dot
getTile(8, 24, pix) # big dot

for y in range(im.size[1]//TILE_SIZE):
    map_file.write("\t\tdc.b\t")
    #return_file.write("\t\tdc.b\t")
    for x in range(im.size[0]//TILE_SIZE):
        t = getTile(x * TILE_SIZE, y * TILE_SIZE, pix)
        map_file.write(str(t))
        #if t in [0,1,2]:
            #return_file.write('0')
        #else:
            #return_file.write('8')
        if x == im.size[0]//TILE_SIZE - 1:
            map_file.write('\n')
            #return_file.write('\n')
        else:
            map_file.write(',')
            #return_file.write(',')

tile_file.close()
map_file.close()
#return_file.close()
