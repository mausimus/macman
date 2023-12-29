from PIL import Image

HERO_SIZE = 16

hero_file = open("hero.inc", "w")

# we use color 4
# hero is 16x16
# 1 word per line

def outputHeroRow(x: int, y: int, pix: any):
    #hero_file.write('\t\tdc.w\t%0,%0,%') # skip first two BPLANES
    hero_file.write('\t\tdc.w\t%') # skip first two BPLANES
    for i in range(HERO_SIZE):
        hero_file.write(str(pix[x + i, y]))
    #hero_file.write(',%0\n') # fourth BPLANE
    hero_file.write(',%0\n') # fourth BPLANE

def outputHero(x: int, y: int, pix: any):
    for j in range(HERO_SIZE):
        outputHeroRow(x, y + j, pix)

print('Hello')
im = Image.open("hero.png")
pix = im.load()

# 0
outputHero(16, 32, pix)
outputHero(0, 32, pix)
# 1
outputHero(16, 0, pix)
outputHero(0, 0, pix)
# 2
outputHero(16, 48, pix)
outputHero(0, 48, pix)
# 3
outputHero(16, 16, pix)
outputHero(0, 16, pix)

hero_file.close()

