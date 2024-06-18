import os
from PIL import Image

input_directory = '.'
output_directories = {
    'N': './N/',
    'E': './E/',
    'S': './S/',
    'W': './W/'
}

for dir_path in output_directories.values():
    os.makedirs(dir_path, exist_ok=True)

files = os.listdir(input_directory)

for file_name in files:
    if file_name.endswith('.png'):
        image_path = os.path.join(input_directory, file_name)
        img = Image.open(image_path)
        
        img.save(os.path.join(output_directories['N'], file_name))
        
        img_90 = img.rotate(-90, expand=True)
        img_90.save(os.path.join(output_directories['E'], file_name))
        
        img_180 = img_90.rotate(-90, expand=True)
        img_180.save(os.path.join(output_directories['S'], file_name))
        
        img_270 = img_180.rotate(-90, expand=True)
        img_270.save(os.path.join(output_directories['W'], file_name))

print("Images processed and saved to respective directories.")