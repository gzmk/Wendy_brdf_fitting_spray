%fitting brdf to images

% Idea: I might be able to store the params in an array and write them into
% the conditions file at each iteration - take a look at this
function costIm = renderIm_2params(var)
%% to write new conditions file with replaced params
% write to file in tabular form
% var = XBest; % this is to re-render the best fits
% var = [0.0760; 0.2168; 0.0472]; % this is for test

% THIS IS FOR MONOCHROMATIC RENDERING

% ro_s = var(1)/(var(1)+var(2));
% ro_d = var(2)/(var(1)+var(2));
% % alphau = var(3);
% alphau = fixedalpha;
% light = (var(1)+var(2));

ro_s = ['300:',num2str(var(1)),' 800:',num2str(var(1))];
ro_d = ['300:', num2str(1-var(1)), ' 800:', num2str(1-var(1))];
alphau = var(2); % alphau and alphav should always be the same value for isotropic brdf
light = ['300:', num2str(1), ' 800:',num2str(1)];
mycell = {ro_s, ro_d, alphau,light};

T = cell2table(mycell, 'VariableNames', {'ro_s' 'ro_d' 'alphau' 'light'});
writetable(T,'/scratch/gk925/Wendy_brdf_fitting_spray/better_gloss80_fit/sphere_3params_Conditions.txt','Delimiter','\t')
%% Rendering bit

% Set preferences
setpref('RenderToolbox3', 'workingFolder', '/scratch/gk925/Wendy_brdf_fitting_spray/better_gloss80_fit');

% use this scene and condition file. 
parentSceneFile = 'test_sphere.dae';
% WriteDefaultMappingsFile(parentSceneFile); % After this step you need to edit the mappings file

conditionsFile = 'sphere_3params_Conditions.txt';
% mappingsFile = 'sphere_3params_DefaultMappings.txt';
mappingsFile = '80v2gloss_DefaultMappings.txt';

% Make sure all illuminants are added to the path. 
addpath(genpath(pwd))

% Choose batch renderer options.

% hints.imageWidth = 4012;
% hints.imageHeight = 6034;
% hints.imageWidth = 600;% these are for quick rendering
% hints.imageHeight = 800;
hints.imageWidth = 668;% this is isotropic scaling (orig. size divided by 4)
hints.imageHeight = 1005;
hints.renderer = 'Mitsuba';

datetime=datestr(now);
datetime=strrep(datetime,':','_'); %Replace colon with underscore
datetime=strrep(datetime,'-','_');%Replace minus sign with underscore
datetime=strrep(datetime,' ','_');%Replace space with underscore
%hints.recipeName = ['Test-SphereFit' datetime];
hints.recipeName = ['Test-SphereFit' date];

ChangeToWorkingFolder(hints);

% nativeSceneFiles = MakeSceneFiles(parentSceneFile, '', mappingsFile, hints);
nativeSceneFiles = MakeSceneFiles(parentSceneFile, conditionsFile, mappingsFile, hints);
radianceDataFiles = BatchRender(nativeSceneFiles, hints);

%comment all this out
toneMapFactor = 10;
isScale = true;
montageName = sprintf('%s (%s)', 'Test-SphereFit', hints.renderer);
montageFile = [montageName '.png'];
[SRGBMontage, XYZMontage] = ...
    MakeMontage(radianceDataFiles, montageFile, toneMapFactor, isScale, hints);

% load the monochromatic image and display it
imPath = ['/scratch/gk925/Wendy_brdf_fitting_spray/better_gloss80_fit/', hints.recipeName, '/renderings/Mitsuba/test_sphere-001.mat']
load(imPath, 'multispectralImage');
im2 = multispectralImage;
% figure;imshow(im2(:,:,1))

%% calculate the ssd (error) between two images
% dcraw command: -4 -d -v -w -b 3.0 DSC_0111_70gloss.pgm
% -b 3.0 makes it 3 times brighter
% gloss40 = imread('registered_photo.pgm','pgm');
% gloss = imread('registered40.pgm','pgm'); % turn this into a variable

% prepare a mask image for %40
mask = zeros(1005,668);
mask(375:585,256:450)=1;

load('registered80v2.mat') % make this a variable
photo = renderRegisteredAdjusted;
masked_photo = mask.*photo;

mean_photo = mean(mean(masked_photo));
photoNorm = masked_photo./(mean_photo);

% black = imread('DSC_0112.pgm')';
% imblack = imresize(black, [1005,668]);
% imblack2 = double(imblack)/65535;
% image1 = photo-imblack2;

renderedIm = im2(:,:,1); %for multispectral rendering
% renderedIm = im2;
mean_render = mean(mean(renderedIm));
renderedImNorm = renderedIm./(mean_render);


diff = photoNorm-renderedImNorm;
costIm = sum(sum(diff.^2));

% cost_arr = [cost_arr;costIm];
% % past_params = [past_params;var'];
% past_params = [past_params;var]; % this for grid search as it takes in row arrays

return;



