function [] = to_bw(file, output, thres)
    l = size(file,2);
    ext = file(l-3:l);
    if (strcmp(ext, '.png'))
        BG = [1,1,1];
        img = imread(file, 'BackgroundColor', BG);
    else
        img = imread(file);
    end
    
    dim = size(img);
    if (dim(end) == 3 || dim(end) == 4)
        img = rgb2gray(img);
    end

    tresh = 255 * thres;

    a = find(img < tresh);
    b = find(img >= tresh);

    img(img < tresh) = 0;
    img(img >= tresh) = 255;

    imwrite(img, output)
end
