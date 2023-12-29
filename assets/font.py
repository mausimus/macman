from PIL import Image

FONT_SIZE = 8

font_file = open("font.inc", "w")

def charPrint(x: int, y: int, pix: any):
    pr = ""
    for i in range(FONT_SIZE):
        for j in range(FONT_SIZE):
            pr += str(pix[x + j, y + i])
    return pr

def outputCharRow(pr: str):
    font_file.write('\t\tdc.b\t%' + pr + ',%0\n') # as words

def outputChar(pr: str):
    outputCharRow(pr[0:8])
    outputCharRow(pr[8:16])
    outputCharRow(pr[16:24])
    outputCharRow(pr[24:32])
    outputCharRow(pr[32:40])
    outputCharRow(pr[40:48])
    outputCharRow(pr[48:56])
    outputCharRow(pr[56:64])

print('Hello')
im = Image.open("font.png")
pix = im.load()

for i in range(18):
    font_file.write('; char ' + str(i) + '\n')
    c = charPrint(i * FONT_SIZE, 0, pix)
    outputChar(c)

font_file.close()
