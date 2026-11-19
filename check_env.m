disp(['MATLAB ' version])
disp(['ImageToolbox=' num2str(license('test','Image_Toolbox'))])
disp(['rawread_exist=' num2str(exist('rawread','file')) '  rawinfo_exist=' num2str(exist('rawinfo','file'))])
p=fullfile('D:\Desktop\isp\raw','sample1.ARW');
if exist('rawinfo','file')
  try
    info=rawinfo(p);
    fn=fieldnames(info);
    for k=1:numel(fn)
      v=info.(fn{k});
      try
        if ischar(v); disp([fn{k} ': ' v]);
        elseif isstring(v); disp([fn{k} ': ' char(v)]);
        else; disp([fn{k} ' = ' mat2str(v)]); end
      catch; end
    end
  catch e
    disp(['rawinfo ERR: ' e.message])
  end
end
if exist('rawread','file')
  try
    d=rawread(p);
    disp(['rawread class=' class(d) ' size=' mat2str(size(d))])
  catch e
    disp(['rawread ERR: ' e.message])
  end
end
