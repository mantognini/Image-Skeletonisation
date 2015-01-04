function [] = skel(file, output)
    img = imread(file);
    img = not(img);
    img = bwmorph(img, 'thin', Inf);
    img = not(img);
    imwrite(img, output);
end
