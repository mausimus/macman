from PIL import Image

SPRITE_SIZE = 16
NUM_FRAMES = 16

sprites_file = open("sprites.inc", "w")
palette_file = open("palette.inc", "w")

def exportLine(x: int, y: int, pix: any, colors: dict):
    pr = ""
    for i in range(SPRITE_SIZE):
        pr += str(colors[str(pix[x + i, y])])
    
    sprites_file.write('\t\tdc.w\t%' + pr.replace('2','0').replace('3','1') + ',%' + pr.replace('1','0').replace('2', '1').replace('3', '1') + '\n')

def exportSprite(x: int, y: int, pix: any, pal: any):
    # lookup colors
    colors = {"0":0}
    c_num = 1
    for i in range(SPRITE_SIZE * NUM_FRAMES):
        for j in range(SPRITE_SIZE):
            c = str(pix[x + i, y + j])
            if c != '0' and c not in colors:
                colors[c] = c_num
                print('col', c, '=', c_num)
                c_num += 1

    sprites_file.write('; sprite x = ' + str(x) + ', y = ' + str(y) + '\n')
   
    for f in range(NUM_FRAMES):
        sprites_file.write('; frame' + str(f) + '\n')
        sprites_file.write('\t\tdc.w\t' + str(100 * 256 + (80 + x * 2)) + ',' + str(116 * 256) + '\n')
        for j in range(SPRITE_SIZE):
            exportLine(x + f * SPRITE_SIZE, y + j, pix, colors)
        sprites_file.write('\t\tdc.w\t%0,%0\n')
    
    palette_file.write('\t\tdc.w\t')
    for cn in range(4):
        for c in colors:
            if colors[c] == cn:
                for p in pal:
                    if pal[p] == int(c):
                        palette_file.write('$0' + f'{p[0]//16:x}' + f'{p[1]//16:x}' + f'{p[2]//16:x}')
                        if cn != 3:
                            palette_file.write(',')
    palette_file.write('\n')

def exportZeroSprite():
    sprites_file.write('; zero sprite\n')
    sprites_file.write('\t\tdc.w\t%0,%0\n')
    for i in range(SPRITE_SIZE):
        sprites_file.write('\t\tdc.w\t%0,%0\n')
    sprites_file.write('\t\tdc.w\t%0,%0\n')

print('Hello')
im = Image.open("sprites.png")
pix = im.load()

exportZeroSprite()
exportSprite(0, 0, pix, im.palette.colors)
exportSprite(0, 16, pix, im.palette.colors)
exportSprite(0, 32, pix, im.palette.colors)
exportSprite(0, 48, pix, im.palette.colors)

sprites_file.close()
palette_file.close()
