from PIL import Image

LOGO_W = 16
LOGO_H = 4

logo_file = open("logo.inc", "w")

def logoPrint(pix: any):
    for j in range(LOGO_H):
        logo_file.write('\t\tdc.w\t')
        for i in range(LOGO_W//16):
            logo_file.write('%')
            for b in range(16):
                logo_file.write(str(pix[i * 16 + b, j]))
            if i != LOGO_W//16-1:
                logo_file.write(',')
        logo_file.write('\n')

print('Hello')
im = Image.open("logo.png")
pix = im.load()

logoPrint(pix)

logo_file.close()
