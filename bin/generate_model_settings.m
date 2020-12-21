function rootdir = generate_model_settings(rootdir)

    files = dir(rootdir+"*/**/prep.m");

    for f = 1:length(files)
        filedir = files(f).folder;
        cd(filedir)
        prep(filedir)
    end

end
