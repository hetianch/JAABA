function varargout = JLabel(varargin)
% JLabel: Start up the JAABA program
%
% This program is part of JAABA.
%
% JAABA: The Janelia Automatic Animal Behavior Annotator
% Copyright 2012, Kristin Branson, HHMI Janelia Farm Resarch Campus
% http://jaaba.sourceforge.net/
% bransonk@janelia.hhmi.org
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License (version 3 pasted in LICENSE.txt) for 
% more details.

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @JLabel_OpeningFcn, ...
                   'gui_OutputFcn',  @JLabel_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1}) && exist(varargin{1}), %#ok<EXIST>
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

function SetSplashStatus(hsplashstatus,varargin)

if ishandle(hsplashstatus),
  set(hsplashstatus,'String',sprintf(varargin{:}));
else
  fprintf([varargin{1},'\n'],varargin{2:end});
end

% --- Executes just before JLabel is made visible.
function JLabel_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to JLabel (see VARARGIN)


% To help with merging with Adam -- Mayank, 6 march 2012 
set(handles.automaticTimelineBottomRowPopup,'String',...
 {'None','Validated','Old','Loaded','Postprocessed','Distance'});

handles.menu_classifier_compareFrames = uimenu(handles.menu_classifier,...
 'Label','Find Similar Frames','Callback',...
@menu_classifier_compareFrames_Callback);


handles.guidata = JLabelGUIData();

% parse optional inputs
[handles.guidata.classifierfilename,...
  handles.guidata.configfilename,...
  handles.guidata.defaultpath,...
  handles.guidata.isgroundtruthmode,...
  handles.guidata.hsplash,...
  handles.guidata.hsplashstatus] = ...
  myparse(varargin,...
  'classifierfilename','',...
  'configfilename','',...
  'defaultpath','',...
  'groundtruthmode',false,...
  'hsplash',[],...
  'hsplashstatus',[]);

if isempty(handles.guidata.hsplash),
  [handles.guidata.hsplash,handles.guidata.hsplashstatus] = JAABASplashScreen();
end
SetSplashStatus(handles.guidata.hsplashstatus,'Initializing Edit Files GUI...');

handles.output = handles.figure_JLabel;
% initialize statusbar

handles.guidata.status_bar_text = sprintf('Status: No experiment loaded');
handles.guidata.idlestatuscolor = [0,1,0];
handles.guidata.busystatuscolor = [1,0,1];
handles.guidata.movie_height = 100;
handles.guidata.movie_width = 100;
handles.guidata.movie_depth = 1;
handles.guidata.tempname = tempname();
ClearStatus(handles);

[handles,success] = JLabelEditFiles('JLabelHandle',handles,...
  'JLabelSplashHandle',handles.guidata.hsplash);

set(handles.figure_JLabel,'pointer','watch');

if ~success,
  guidata(hObject,handles);
  delete(hObject);
  return;
end

handles.guidata.data.SetStatusFn(@(s) SetStatusCallback(s,handles.figure_JLabel));
handles.guidata.data.SetClearStatusFn(@() ClearStatusCallback(handles.figure_JLabel));

% read configuration
[handles,success] = LoadConfig(handles);
if ~success,
  guidata(hObject,handles);
  delete(hObject);
  return;
end

% get relative locations of stuffs
% handles = GetGUIPositions(handles);
% 
% % initialize data
% handles = InitializeState(handles);
% 
% % initialize plot handles
% handles = InitializePlots(handles);
% 
% % load classifier
% if ~isempty(handles.guidata.classifierfilename),
%   if exist(handles.guidata.classifierfilename,'file'),
%     [success,msg] = handles.guidata.data.SetClassifierFileName(handles.guidata.classifierfilename);
%     if ~success,
%       warning(msg);
%       SetStatus(handles,'Error loading classifier from file');
%     end
%   end
% end
% 
% if isempty(handles.guidata.data.expdirs),
%   guidata(hObject,handles);
%   menu_file_editfiles_Callback(handles.figure_JLabel, [], handles);
%   handles = guidata(hObject);
% end

handles = InitSelectionCallbacks(handles);

if handles.guidata.data.nexps > 0 && handles.guidata.data.expi == 0,
  handles = SetCurrentMovie(handles,1);
else
  handles = SetCurrentMovie(handles,handles.guidata.data.expi);
end

handles = UpdateGUIGroundTruthMode(handles);

% keypress callback for all non-edit text objects
RecursiveSetKeyPressFcn(handles.figure_JLabel);

% enable gui
EnableGUI(handles);


if ismac, % On mac change the foreground color to black.
  allpopups = findall(hObject,'Style','popup');
  set(allpopups,'ForegroundColor',[0 0 0]);
  set(allpopups,'BackgroundColor',[1 1 1]);
end

set(handles.figure_JLabel,'pointer','arrow');


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes JLabel wait for user response (see UIRESUME)
% UNCOMMENT
%uiwait(handles.figure_JLabel);

function handles = InitSelectionCallbacks(handles)

handles.guidata.callbacks = struct;
handles.guidata.callbacks.figure_WindowButtonMotionFcn = get(handles.figure_JLabel,'WindowButtonMotionFcn');
set(handles.figure_JLabel,'WindowButtonMotionFcn','');

% --- Outputs from this function are returned to the command line.
function varargout = JLabel_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = hObject;
% UNCOMMENT
% if isfield(handles,'data'),
%   varargout{1} = handles.guidata.data;
% else
%   varargout{1} = [];
% end
% SaveRC(handles);
% delete(handles.figure_JLabel);

function handles = InitializePlots(handles)

handles.guidata.axes_preview_curr = 1;
if numel(handles.guidata.axes_previews) > numel(handles.guidata.ts),
  handles.guidata.ts = [handles.guidata.ts,repmat(handles.guidata.ts(end),[1,numel(handles.guidata.axes_previews)-numel(handles.guidata.ts)])];
end

% slider callbacks
for i = 1:numel(handles.guidata.slider_previews),
  fcn = get(handles.guidata.slider_previews(i),'Callback');
  %set(handles.guidata.slider_previews(i),'Callback','');
  if i == 1,
    handles.guidata.hslider_listeners = handle.listener(handles.guidata.slider_previews(i),...
      'ActionEvent',fcn);
  else
    handles.guidata.hslider_listeners(i) = handle.listener(handles.guidata.slider_previews(i),...
      'ActionEvent',fcn);
  end

end

% fly current positions
handles.guidata.hflies = zeros(handles.guidata.nflies_curr,numel(handles.guidata.axes_previews));
handles.guidata.hflies_extra = zeros(handles.guidata.nflies_curr,handles.guidata.nextra_markers,numel(handles.guidata.axes_previews));
handles.guidata.hfly_markers = zeros(handles.guidata.nflies_curr,numel(handles.guidata.axes_previews));
% fly path
handles.guidata.htrx = zeros(handles.guidata.nflies_label,numel(handles.guidata.axes_previews));

% choose colors for flies
% TODO: change hard-coded colormap
handles.guidata.fly_colors = jet(handles.guidata.nflies_curr)*.7;
handles.guidata.fly_colors = handles.guidata.fly_colors(randperm(handles.guidata.nflies_curr),:);

handles.guidata.hlabel_curr = nan(1,numel(handles.guidata.axes_previews));
for i = 1:numel(handles.guidata.axes_previews),
  cla(handles.guidata.axes_previews(i),'reset');

  % image in axes_preview
  handles.guidata.himage_previews(i) = imagesc(0,'Parent',handles.guidata.axes_previews(i),[0,255]);
  set(handles.guidata.himage_previews(i),'HitTest','off');
  axis(handles.guidata.axes_previews(i),'equal');
  
  set(handles.guidata.axes_previews(i),'ButtonDownFcn',@(hObject,eventdata) JLabel('axes_preview_ButtonDownFcn',hObject,eventdata,guidata(hObject)));
  hold(handles.guidata.axes_previews(i),'on');

  % labeled behaviors
  handles.guidata.hlabels = nan(1,handles.guidata.data.nbehaviors);
  handles.guidata.hpredicted = nan(1,handles.guidata.data.nbehaviors);
  handles.guidata.hlabelstarts = nan(1,handles.guidata.data.nbehaviors);
  for j = 1:handles.guidata.data.nbehaviors,
    handles.guidata.hlabels(j) = plot(handles.guidata.axes_previews(i),nan,nan,'-',...
      'color',handles.guidata.labelcolors(j,:),'linewidth',5,'HitTest','off');
    handles.guidata.hpredicted(j) = plot(handles.guidata.axes_previews(i),nan,nan,'-',...
      'color',handles.guidata.labelcolors(j,:),'linewidth',5,'HitTest','off');
    % start of label
    handles.guidata.hlabelstarts(j) = plot(handles.guidata.axes_previews(i),nan,nan,'v',...
      'color',handles.guidata.labelcolors(j,:),'markerfacecolor',handles.guidata.labelcolors(j,:),...
      'HitTest','off');
    
    set(handles.guidata.axes_previews(i),'Color','k','XColor','w','YColor','w');
    
  end
  
  if handles.guidata.plot_labels_manual,
    set(handles.guidata.hlabels,'Visible','on');
  else
    set(handles.guidata.hlabels,'Visible','off');
  end
  if handles.guidata.plot_labels_automatic,
    set(handles.guidata.hpredicted,'Visible','on');
  else
    set(handles.guidata.hpredicted,'Visible','off');
  end
  
  % current label plotted on axes
  handles.guidata.hlabel_curr(i) = plot(nan(1,2),nan(1,2),'k-',...
    'Parent',handles.guidata.axes_previews(i),...
    'HitTest','off','Linewidth',5);
  
  % trx of flies
  for j = 1:handles.guidata.nflies_label,
    handles.guidata.htrx(j,i) = plot(handles.guidata.axes_previews(i),nan,nan,'.-',...
      'linewidth',1,'HitTest','off');
  end
  
  % fly current positions
  for fly = 1:handles.guidata.nflies_curr,
    handles.guidata.hflies(fly,i) = plot(handles.guidata.axes_previews(i),nan,nan,'-',...
      'color',handles.guidata.fly_colors(fly,:),'linewidth',3,...
      'ButtonDownFcn',@(hObject,eventdata) JLabel('fly_ButtonDownFcn',hObject,eventdata,guidata(hObject),fly,i));
    for j = 1:handles.guidata.nextra_markers,
      handles.guidata.hflies_extra(fly,j,i) = plot(handles.guidata.axes_previews(i),nan,nan,...
        'Marker',handles.guidata.flies_extra_marker{j},...
        'Color',handles.guidata.fly_colors(fly,:),'MarkerFaceColor',handles.guidata.fly_colors(fly,:),...
        'LineStyle',handles.guidata.flies_extra_linestyle{j},...
        'MarkerSize',handles.guidata.flies_extra_markersize(j),...
        'ButtonDownFcn',@(hObject,eventdata) JLabel('fly_ButtonDownFcn',hObject,eventdata,guidata(hObject),fly,i));
    end
    handles.guidata.hfly_markers(fly,i) = plot(handles.guidata.axes_previews(i),nan,nan,'*',...
      'color',handles.guidata.fly_colors(fly,:),'linewidth',3,...
      'ButtonDownFcn',@(hObject,eventdata) JLabel('fly_ButtonDownFcn',hObject,eventdata,guidata(hObject),fly,i),...
      'Visible','off');
  end

end

% TODO: allow colormap options
colormap(handles.axes_preview,gray(256));

% timelines

% zoom
handles.guidata.hzoom = zoom(handles.figure_JLabel);
handles.guidata.hpan = pan(handles.figure_JLabel);
set(handles.guidata.hzoom,'ActionPostCallback',@(hObject,eventdata) PostZoomCallback(hObject,eventdata,guidata(eventdata.Axes)));
set(handles.guidata.hpan,'ActionPostCallback',@(hObject,eventdata) PostZoomCallback(hObject,eventdata,guidata(eventdata.Axes)));

% manual timeline
timeline_axes_color = get(handles.panel_timelines,'BackgroundColor');
handles.guidata.himage_timeline_manual = image(zeros([1,1,3]),'Parent',handles.axes_timeline_manual);
set(handles.guidata.himage_timeline_manual,'HitTest','off');
hold(handles.axes_timeline_manual,'on');
%handles.htimeline_manual_starts = plot(handles.axes_timeline_manual,nan,nan,'w-','HitTest','off');
ylim = [.5,1.5];
ydata = [ylim(1)+diff(ylim)*.025,ylim(2)-diff(ylim)*.025];
handles.guidata.htimeline_label_curr = patch(nan(1,5),ydata([1,2,2,1,1]),'k',...
  'Parent',handles.axes_timeline_manual,'LineStyle','--','EdgeColor','w',...
  'HitTest','off','Linewidth',3,'Clipping','on');
if handles.guidata.plot_labels_manual,
  set(handles.timeline_label_manual,'ForegroundColor',handles.guidata.emphasiscolor,'FontWeight','bold');
else
  set(handles.timeline_label_manual,'ForegroundColor',handles.guidata.unemphasiscolor,'FontWeight','normal');
end

set(handles.axes_timeline_manual,'YTick',[]);
setAxesZoomMotion(handles.guidata.hzoom,handles.axes_timeline_manual,'horizontal');
setAllowAxesPan(handles.guidata.hpan,handles.axes_timeline_manual,false);

% auto timeline
ydata_im = [2/3,4/3];
handles.guidata.himage_timeline_auto = image(zeros([3,1,3]),'Parent',handles.axes_timeline_auto);
set(handles.guidata.himage_timeline_auto,'YData',ydata_im);
set(handles.guidata.himage_timeline_auto,'HitTest','off');
hold(handles.axes_timeline_auto,'on');
%handles.htimeline_auto_starts = plot(handles.axes_timeline_auto,nan,nan,'w-','HitTest','off');
set(handles.axes_timeline_auto,'YTick',[]);
setAxesZoomMotion(handles.guidata.hzoom,handles.axes_timeline_auto,'horizontal');
setAllowAxesPan(handles.guidata.hpan,handles.axes_timeline_auto,false);
if handles.guidata.plot_labels_automatic,
  set(handles.timeline_label_automatic,'ForegroundColor',handles.guidata.emphasiscolor,'FontWeight','bold');
else
  set(handles.timeline_label_automatic,'ForegroundColor',handles.guidata.unemphasiscolor,'FontWeight','normal');
end

for h = handles.guidata.axes_timeline_labels,
  set(h,'YLim',[.5,1.5]);
end

% properties
propi = 1;
handles.guidata.htimeline_data(propi) = plot(handles.guidata.axes_timeline_props(propi),nan,nan,'w.-','HitTest','off');
hold(handles.guidata.axes_timeline_props(propi),'on');

% whether the manual and auto match
handles.guidata.htimeline_errors = plot(handles.axes_timeline_manual,nan,nan,'-',...
  'color',handles.guidata.incorrectcolor,'HitTest','off','Linewidth',5);
% new suggestions
handles.guidata.htimeline_suggestions = plot(handles.axes_timeline_manual,nan,nan,'-',...
  'color',handles.guidata.suggestcolor,'HitTest','off','Linewidth',5);

% gt suggestions
handles.guidata.htimeline_gt_suggestions = plot(handles.axes_timeline_manual,nan,nan,'-',...
  'color',handles.guidata.suggestcolor,'HitTest','off','Linewidth',5);

handles.guidata.menu_view_zoom_options = setdiff(findall(handles.menu_view_zoom,'Type','uimenu'),...
  handles.menu_view_zoom);

% suggest timeline
% handles.himage_timeline_suggest = image(zeros([1,1,3]),'Parent',handles.axes_timeline_suggest);
% set(handles.himage_timeline_suggest,'HitTest','off');
% hold(handles.axes_timeline_suggest,'on');
% handles.htimeline_suggest_starts = plot(handles.axes_timeline_suggest,nan,nan,'w-','HitTest','off');

% error timeline
% handles.himage_timeline_error = image(zeros([1,1,3]),'Parent',handles.axes_timeline_error);
% set(handles.himage_timeline_error,'HitTest','off');
% hold(handles.axes_timeline_error,'on');
% handles.htimeline_error_starts = plot(handles.axes_timeline_error,nan,nan,'w-','HitTest','off');

for i = 1:numel(handles.guidata.axes_timeline_props),
  setAxesZoomMotion(handles.guidata.hzoom,handles.guidata.axes_timeline_props(i),'vertical');
  setAllowAxesPan(handles.guidata.hpan,handles.guidata.axes_timeline_props(i),true);
  setAxesPanMotion(handles.guidata.hpan,handles.guidata.axes_timeline_props(i),'vertical');
end

for i = 1:numel(handles.guidata.axes_timelines),
  hold(handles.guidata.axes_timelines(i),'on');
  set(handles.guidata.axes_timelines(i),'XColor','w','YColor','w','Color',timeline_axes_color);
end

handles.guidata.hcurr_timelines = nan(size(handles.guidata.axes_timelines));
for i = 1:numel(handles.guidata.axes_timelines),
  handles.guidata.hcurr_timelines(i) = plot(handles.guidata.axes_timelines(i),nan(1,2),[-10^6,10^6],'y-','HitTest','off','linewidth',2);
end
handles.guidata.hselection = nan(size(handles.guidata.axes_timelines));
for i = 1:numel(handles.guidata.axes_timelines),
  ylim = [.5,1.5];
  ydata = [ylim(1)+diff(ylim)*.025,ylim(2)-diff(ylim)*.025];
  handles.guidata.hselection(i) = ...
    plot(handles.guidata.axes_timelines(i),nan(1,5),ydata([1,2,2,1,1]),'--','color',handles.guidata.selection_color,...
    'HitTest','off','Linewidth',3);
end

for i = 2:numel(handles.guidata.axes_timelines),
%  if handles.guidata.axes_timelines(i) ~= handles.axes_timeline_error,
%  if handles.guidata.axes_timelines(i) ~= handles.axes_timeline_auto,
    set(handles.guidata.axes_timelines(i),'XTickLabel',{});
%  end
end

linkaxes(handles.guidata.axes_timelines,'x');

set(handles.guidata.htimeline_gt_suggestions,'Visible','off');
if handles.guidata.data.IsGTMode(),
  set(handles.menu_view_plot_labels_automatic,'Visible','off');
end

% for faster refreshing
set(handles.axes_preview,'BusyAction','cancel');
set(handles.guidata.hflies,'EraseMode','none');
if ~isempty(handles.guidata.hflies_extra),
  set(handles.guidata.hflies_extra,'EraseMode','none');
end
set(handles.guidata.htrx,'EraseMode','none');
set(handles.guidata.hfly_markers,'EraseMode','none');

handles = UpdateGUIGroundTruthMode(handles);

%for i = 1:numel(handles.guidata.axes_timelines),
%  setAxesZoomMotion(handles.guidata.hzoom,handles.guidata.axes_timelines(i),'horizontal');
%end

% timeline callbacks
% fcn = @(hObject,eventdata) JLabel('axes_timeline_ButtonDownFcn',hObject,eventdata,guidata(hObject));
% for i = 1:numel(handles.guidata.axes_timelines),
%   set(handles.guidata.axes_timelines(i),'ButtonDownFcn',fcn);
% end



function cache_thread(N,HWD,cache_filename,movie_filename)

if isempty(movie_filename),
  return;
end

Mframenum = memmapfile(cache_filename, 'Writable', true, 'Format', 'double', 'Repeat', N);
Mlastused = memmapfile(cache_filename, 'Writable', true, 'Format', 'double', 'Repeat', N, 'Offset', N*8);
Mimage    = memmapfile(cache_filename, 'Writable', true, 'Format', {'uint8' HWD 'x'},  'Repeat', N, ...
    'Offset', 2*N*8);

readframe=get_readframe_fcn(movie_filename);

while true
  idx=find(isnan(Mlastused.Data));
  if(~isempty(idx))
    idx2=argmax(Mframenum.Data(idx));
    fnum = Mframenum.Data(idx(idx2));
    dd = uint8(readframe(fnum));
    pause(0.0003);
    % MK: Cache the read frame to reduce the number of clashes with
    % UpdatePlots
    if Mframenum.Data(idx(idx2))== fnum
      Mimage.Data(idx(idx2)).x = dd;
      Mlastused.Data(idx(idx2)) = now;
      Mframenum.Data(idx(idx2)) = fnum;
    end
  else
    pause(1);
  end
end


function UpdatePlots(handles,varargin)

persistent Mframenum Mlastused Mimage movie_filename

if strcmp(varargin{1},'CLEAR'),
  %fprintf('Clearing UpdatePlots data\n');
  try
    if isfield(handles,'guidata') && ~isempty(handles.guidata.cache_thread),
      delete(handles.guidata.cache_thread);
      handles.guidata.cache_thread = [];
    end
    Mframenum = struct('Data',[]);
    Mlastused = struct('Data',[]);
    Mimage = struct('Data',[]);
    movie_filename = '';
  catch ME,
    warning('Error when trying to clear UpdatePlots data: %s',getReport(ME));
  end
  return;
end

if(handles.guidata.data.ismovie && (isempty(movie_filename) || ~strcmp(movie_filename,handles.guidata.movie_filename)))
  movie_filename=handles.guidata.movie_filename;
  N=200;  % cache size
  HWD = [handles.guidata.movie_height handles.guidata.movie_width handles.guidata.movie_depth];

  % release data used in thread
  if ~isempty(handles.guidata.cache_thread),
    delete(handles.guidata.cache_thread);
    handles.guidata.cache_thread = [];
  end
  Mframenum = struct('Data',[]); %#ok<NASGU>
  Mlastused = struct('Data',[]); %#ok<NASGU>
  Mimage = struct('Data',[]); %#ok<NASGU>
  
  cache_filename= [handles.guidata.tempname 'cache-' num2str(feature('getpid')) '.dat'];
  fid=fopen(cache_filename,'w');
  if fid < 1,
    pause(.1);
    fid=fopen(cache_filename,'w');
  end

  for i = 1:5,
    if fid >= 1,
      break;
    end
    new_cache_filename = fullfile(tempdir(),['cache-' num2str(feature('getpid')) '_' num2str(i) '.dat']);
    warning('Could not open cache file %s, trying %s',cache_filename,new_cache_filename);
    cache_filename = new_cache_filename;
    fid=fopen(cache_filename,'w');
  end
    
  fwrite(fid,zeros(1,N),'double');
  fwrite(fid,zeros(1,N),'double');
  fwrite(fid,zeros(1,N*prod(HWD),'uint8'),'uint8');  % need to make this work for other formats
  fclose(fid);
  Mframenum = memmapfile(cache_filename, 'Writable', true, 'Format', 'double', 'Repeat', N);
  Mlastused = memmapfile(cache_filename, 'Writable', true, 'Format', 'double', 'Repeat', N, 'Offset', N*8);
  Mimage =    memmapfile(cache_filename, 'Writable', true, 'Format', {'uint8' HWD 'x'},  'Repeat', N, 'Offset', 2*N*8);

  handles.guidata.cache_thread=batch(@cache_thread,0,...
    {N,HWD,cache_filename,handles.guidata.movie_filename},...
    'CaptureDiary',true,'AdditionalPaths',{'../filehandling','../misc'});
  if(ismac)  pause(10);  end  % BJA: only necessary if on a mac and using a remote file system, not sure why
end

% WARNING: we directly access handles.guidata.data.trx for speed here -- 
% REMOVED! NOT SO SLOW

[axes,refreshim,refreshflies,refreshtrx,refreshlabels,...
  refresh_timeline_manual,refresh_timeline_auto,refresh_timeline_suggest,refresh_timeline_error,...
  refresh_timeline_xlim,refresh_timeline_hcurr,...
  refresh_timeline_props,refresh_timeline_selection,...
  refresh_curr_prop,refresh_GT_suggestion] = ...
  myparse(varargin,'axes',1:numel(handles.guidata.axes_previews),...
  'refreshim',true,'refreshflies',true,'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',true,...
  'refresh_timeline_auto',true,...
  'refresh_timeline_suggest',true,...
  'refresh_timeline_error',true,...
  'refresh_timeline_xlim',true,...
  'refresh_timeline_hcurr',true,...
  'refresh_timeline_props',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',true,...
  'refresh_GT_suggestion',true);

% make sure data for this experiment is loaded
% if handles.guidata.expi ~= handles.guidata.data.expi,
%   SetStatus('Preloading data for experiment %s, flies %s',handles.guidata.data.expnames{handles.guidata.expi},mat2str(handles.guidata.flies));
%   handles.guidata.data.PreLoad(handles.guidata.expi,handles.guidata.flies);
% end

% update timelines
if refresh_timeline_manual,
  set(handles.guidata.himage_timeline_manual,'CData',handles.guidata.labels_plot.im);
  %tmp = find(handles.guidata.labels_plot.isstart);
  %nstarts = numel(tmp);
  %tmpx = reshape(cat(1,repmat(tmp,[2,1]),nan(1,nstarts)),[3*nstarts,1]);
  %tmpy = reshape(repmat([.5;1.5;nan],[1,nstarts]),[3*nstarts,1]);
  %set(handles.htimeline_manual_starts,'XData',tmpx,'YData',tmpy);  
  if handles.guidata.label_state ~= 0,
    ts = sort([handles.label_t0,handles.guidata.ts(1)]);
    ts(1) = max(ts(1),handles.guidata.ts(1)-(handles.guidata.timeline_nframes-1)/2);
    ts(2) = min(ts(2),handles.guidata.ts(1)+(handles.guidata.timeline_nframes-1)/2);
    ts = ts + [-.5,.5];
    set(handles.guidata.htimeline_label_curr,'XData',ts([1,1,2,2,1]));
  end
end

if refresh_timeline_auto,
  set(handles.guidata.himage_timeline_auto,'CData',handles.guidata.labels_plot.predicted_im);
  pred = handles.guidata.data.GetPredictedIdx(handles.guidata.expi,handles.guidata.flies,handles.guidata.ts(1),handles.guidata.ts(1));
  if pred.predictedidx~=0
    cur_scores = handles.guidata.data.NormalizeScores(pred.scoresidx);
    set(handles.text_scores,'String',sprintf('%+.2f',cur_scores));
  else
    set(handles.text_scores,'String','');
  end
    
end
if refresh_timeline_suggest,
  set(handles.guidata.htimeline_suggestions,'XData',handles.guidata.labels_plot.suggest_xs,...
    'YData',zeros(size(handles.guidata.labels_plot.suggest_xs))+1.5);
  %set(handles.himage_timeline_suggest,'CData',handles.guidata.labels_plot.suggested_im);
end
if refresh_timeline_error,
  set(handles.guidata.htimeline_errors,'XData',handles.guidata.labels_plot.error_xs,...
  'YData',zeros(size(handles.guidata.labels_plot.error_xs))+1.5);
  %set(handles.himage_timeline_error,'CData',handles.guidata.labels_plot.error_im);
end
if refresh_GT_suggestion && ~isempty(fieldnames(handles.guidata.labels_plot)),
  set(handles.guidata.htimeline_gt_suggestions,'XData',handles.guidata.labels_plot.suggest_gt,...
    'YData',zeros(size(handles.guidata.labels_plot.suggest_gt))+1.5);
end


if refresh_timeline_xlim,
  xlim = [handles.guidata.ts(1)-(handles.guidata.timeline_nframes-1)/2,...
    handles.guidata.ts(1)+(handles.guidata.timeline_nframes-1)/2];
  for i = 1:numel(handles.guidata.axes_timelines),
    set(handles.guidata.axes_timelines(i),'XLim',xlim);
    %zoom(handles.guidata.axes_timelines(i),'reset');
  end
end


if refresh_timeline_hcurr,
  set(handles.guidata.hcurr_timelines,'XData',handles.guidata.ts([1,1]));
end
if refresh_timeline_selection,
  tmp = handles.guidata.selected_ts + .5*[-1,1];
  set(handles.guidata.hselection,'XData',tmp([1,1,2,2,1]));
end

if refresh_timeline_props,
  for propi = 1:numel(handles.guidata.perframepropis),
    v = handles.guidata.perframepropis(propi);
    [perframedata,T0,T1] = handles.guidata.data.GetPerFrameData(handles.guidata.expi,handles.guidata.flies,v);
    set(handles.guidata.htimeline_data(propi),'XData',T0:T1,...
      'YData',perframedata);
    %if isnan(handles.guidata.timeline_data_ylims(1,v)),
      ylim = [min(perframedata),max(perframedata)];
      if ylim(2) <= ylim(1),
        ylim(2) = ylim(1)+1;
      end
      set(handles.guidata.axes_timeline_props(propi),'YLim',ylim);
      zoom(handles.guidata.axes_timeline_props(propi),'reset');
    %end
    if ~isnan(handles.guidata.timeline_data_ylims(1,v)),
      ylim = handles.guidata.timeline_data_ylims(:,v);
      set(handles.guidata.axes_timeline_props(propi),'YLim',ylim);
    end
    ydata = [ylim(1)+diff(ylim)*.025,ylim(2)-diff(ylim)*.025];
    set(handles.guidata.hselection(propi),'YData',ydata([1,2,2,1,1]));      
  end
end

%drawnow;

for i = axes,
  
  if refreshim,
    
    if handles.guidata.data.ismovie,

      j = find((Mframenum.Data==handles.guidata.ts(i)) & ...
               (~isnan(Mlastused.Data)) & ...
               (Mlastused.Data>0) ...
               ,1,'first');
      %if(numel(j)>1)  j=j(1);  end
      if isempty(j),
        j = argmin(Mlastused.Data);
        Mframenum.Data(j) = handles.guidata.ts(i);
        Mimage.Data(j).x = uint8(handles.guidata.readframe(handles.guidata.ts(i)));
          % ALT: Added uint8() 2012-09-14.  Without that, threw error when
          % loading a .fmf file, which led to handles.guidata.readframe(handles.guidata.ts(i))
          % being of class double
        %disp(['frame #' num2str(handles.guidata.ts(i)) ' NOT CACHED, len queue = ' ...
        %    num2str(sum(isnan(Mlastused.Data)))]);
      else
        %disp(['frame #' num2str(handles.guidata.ts(i)) ' cached, len queue = ' ...
        %    num2str(sum(isnan(Mlastused.Data)))]);
      end

      Mlastused.Data(j) = now;
      set(handles.guidata.himage_previews(i),'CData',Mimage.Data(j).x);

      % remove from the queue frames preceeding current frame
      j=(Mframenum.Data<handles.guidata.ts(i)) & isnan(Mlastused.Data);
      if(sum(j)>0)
        %disp(['unqueueing frame(s) ' num2str(Mframenum.Data(j)')...
        %    '; current frame = ' num2str(handles.guidata.ts(i))]);
        Mlastused.Data(j) = 0;
        Mframenum.Data(j) = 0;
      end

      % add to the queue frames subsequent to current frame
      tmp=handles.guidata.nframes_jump_go;
      j=setdiff([handles.guidata.ts(i)+[1:tmp -1 -tmp]],Mframenum.Data);
      j=j(find(j>=handles.guidata.t0_curr & j<=handles.guidata.t1_curr));
      [y,idx]=sort(Mlastused.Data);
      idx=idx(1:min([length(j) -1+find(isnan(y),1,'first')]));
      if(~isempty(idx))
        Mframenum.Data(idx) = j(1:length(idx));
        Mlastused.Data(idx) = nan;
      end

    else
      
      set(handles.guidata.himage_previews(i),'Visible','off');
    end
    
  end
  
  % update current position
  if refreshflies,
    if handles.guidata.ts(i) < handles.guidata.t0_curr || handles.guidata.ts(i) > handles.guidata.t1_curr,
      labelidx = [];
    elseif handles.guidata.label_state ~= 0,
      labelidx = handles.guidata.label_state;
    elseif handles.guidata.plot_labels_manual,
      labelidxStruct = handles.guidata.data.GetLabelIdx(handles.guidata.expi,handles.guidata.flies,handles.guidata.ts(i),handles.guidata.ts(i));
      labelidx = labelidxStruct.vals;
    elseif handles.guidata.plot_labels_automatic,
       prediction = handles.guidata.data.GetPredictedIdx(handles.guidata.expi,handles.guidata.flies,handles.guidata.ts(i),handles.guidata.ts(i));
       labelidx = prediction.predictedidx;
    end
    inbounds = handles.guidata.data.firstframes_per_exp{handles.guidata.expi} <= handles.guidata.ts(i) & ...
      handles.guidata.data.endframes_per_exp{handles.guidata.expi} >= handles.guidata.ts(i);
    
    % indices that will be removed
    goodidx = find(handles.guidata.idx2fly~=0);
    idxremove = goodidx(find(~inbounds(handles.guidata.idx2fly(goodidx))));
    fliesadd = find(inbounds & handles.guidata.fly2idx==0);
    if ~isempty(idxremove),
      handles.guidata.fly2idx(~inbounds) = 0;
      handles.guidata.idx2fly(idxremove) = 0;
    end
    idxfree = find(handles.guidata.idx2fly==0);
    if ~isempty(fliesadd),
      for j = 1:numel(fliesadd),
        fly = fliesadd(j);
        handles.guidata.fly2idx(fly) = idxfree(j);
        handles.guidata.idx2fly(idxfree(j)) = fly;
        set(handles.guidata.hflies(idxfree(j),i),'Color',handles.guidata.fly_colors(fly,:));
        set(handles.guidata.hflies_extra(idxfree(j),:,i),...
          'Color',handles.guidata.fly_colors(fly,:),...
          'MarkerFaceColor',handles.guidata.fly_colors(fly,:));
        set(handles.guidata.hfly_markers(idxfree(j),i),...
          'Color',handles.guidata.fly_colors(fly,:));
      end
    end
    if handles.doplottracks,
      isinvisible = handles.guidata.idx2fly == 0;
      set(handles.guidata.hflies(isinvisible,i),'Visible','off');
      set(handles.guidata.hflies_extra(isinvisible,:,i),'Visible','off');
      set(handles.guidata.hfly_markers(isinvisible,i),'Visible','off');
      set(handles.guidata.hflies(~isinvisible,i),'Visible','on');
      set(handles.guidata.hflies_extra(~isinvisible,:,i),'Visible','on');
      set(handles.guidata.hfly_markers(~isinvisible,i),'Visible','on');
    end
    for fly = find(inbounds),

      t = handles.guidata.ts(i);
      pos = handles.guidata.data.GetTrxPos1(handles.guidata.expi,fly,t);
      j = handles.guidata.fly2idx(fly);
      UpdateTargetPosition(handles.guidata.data.targettype,handles.guidata.hflies(j,i),...
        handles.guidata.hflies_extra(j,:,i),pos);

      set(handles.guidata.hfly_markers(j,i),'XData',pos.x,'YData',pos.y);
      sexcurr = handles.guidata.data.GetSex1(handles.guidata.expi,fly,t);
      if lower(sexcurr(1)) == 'm',
        set(handles.guidata.hfly_markers(j,i),'Visible','on');
      else
        set(handles.guidata.hfly_markers(j,i),'Visible','off');
      end
%       updatefly(handles.guidata.hflies(fly,i),...
%         handles.guidata.data.GetTrxX1(handles.guidata.expi,fly,t),...
%         handles.guidata.data.GetTrxY1(handles.guidata.expi,fly,t),...
%         handles.guidata.data.GetTrxTheta1(handles.guidata.expi,fly,t),...
%         handles.guidata.data.GetTrxA1(handles.guidata.expi,fly,t),...
%         handles.guidata.data.GetTrxB1(handles.guidata.expi,fly,t));
%       j = handles.guidata.ts(i) + handles.guidata.data.trx(fly).off;
%       updatefly(handles.guidata.hflies(fly,i),handles.guidata.data.trx(fly).x(j),...
%         handles.guidata.data.trx(fly).y(j),...
%         handles.guidata.data.trx(fly).theta(j),...
%         handles.guidata.data.trx(fly).a(j),...
%         handles.guidata.data.trx(fly).b(j));
      %updatefly(handles.guidata.hflies(fly,i),trx(fly).x,trx(fly).y,trx(fly).theta,trx(fly).a,trx(fly).b);
      if ismember(fly,handles.guidata.flies),
        set(handles.guidata.hflies(j,i),'LineWidth',3);
        if labelidx <= 0,
          set(handles.guidata.hflies(j,i),'Color',handles.guidata.labelunknowncolor);
          set(handles.guidata.hflies_extra(j,:,i),'Color',handles.guidata.labelunknowncolor,...
            'MarkerFaceColor',handles.guidata.labelunknowncolor);
        else
          set(handles.guidata.hflies(j,i),'Color',handles.guidata.labelcolors(labelidx,:),...
            'MarkerFaceColor',handles.guidata.labelcolors(labelidx,:));
        end
      else
        set(handles.guidata.hflies(j,i),'LineWidth',1);
      end
    end
    
    if strcmpi(handles.guidata.preview_zoom_mode,'center_on_fly'),
      ZoomInOnFlies(handles,i);
    elseif strcmpi(handles.guidata.preview_zoom_mode,'follow_fly'),
      KeepFliesInView(handles,i);
    end    
  end

  % update trx
  nprev = handles.guidata.traj_nprev;
  npost = handles.guidata.traj_npost;
  if refreshtrx,
    for j = 1:numel(handles.guidata.flies),
      fly = handles.guidata.flies(j);
      tmp = handles.guidata.ts(i);
      t0 = handles.guidata.data.firstframes_per_exp{handles.guidata.expi}(fly);
      t1 = handles.guidata.data.endframes_per_exp{handles.guidata.expi}(fly);
      ts = max(t0,tmp-nprev):min(t1,tmp+npost);
      set(handles.guidata.htrx(j,i),'XData',handles.guidata.data.GetTrxValues('X1',handles.guidata.expi,fly,ts),...
        'YData',handles.guidata.data.GetTrxValues('Y1',handles.guidata.expi,fly,ts));
      %j0 = max(1,tmp-nprev);
      %j1 = min(handles.guidata.data.trx(fly).nframes,tmp+npost);
      %set(handles.guidata.htrx(j,i),'XData',handles.guidata.data.trx(fly).x(j0:j1),...
      %  'YData',handles.guidata.data.trx(fly).y(j0:j1));
      %trx = handles.guidata.data.GetTrx(handles.guidata.expi,fly,handles.guidata.ts(i)-nprev:handles.guidata.ts(i)+npost);
      %set(handles.guidata.htrx(j,i),'XData',trx.x,'YData',trx.y);
    end
  end  
  
  % update labels plotted
  if refreshlabels,
    for k = 1:numel(handles.guidata.flies),
      fly = handles.guidata.flies(k);
      T0 = handles.guidata.data.firstframes_per_exp{handles.guidata.expi}(fly);
      T1 = handles.guidata.data.endframes_per_exp{handles.guidata.expi}(fly);
%       T0 = handles.guidata.data.GetTrxFirstFrame(handles.guidata.expi,fly);
%       T1 = handles.guidata.data.GetTrxEndFrame(handles.guidata.expi,fly);
      t0 = min(T1,max(T0,handles.guidata.ts(i)-nprev));
      t1 = min(T1,max(T0,handles.guidata.ts(i)+npost));
      for j = 1:handles.guidata.data.nbehaviors,
        xplot = handles.guidata.labels_plot.x(:,handles.guidata.labels_plot_off+t0:handles.guidata.labels_plot_off+t1,j,k);
        yplot = handles.guidata.labels_plot.y(:,handles.guidata.labels_plot_off+t0:handles.guidata.labels_plot_off+t1,j,k);
        set(handles.guidata.hlabels(j),'XData',xplot(:),'YData',yplot(:));
        xpred = handles.guidata.labels_plot.predx(:,handles.guidata.labels_plot_off+t0:handles.guidata.labels_plot_off+t1,j,k);
        ypred = handles.guidata.labels_plot.predy(:,handles.guidata.labels_plot_off+t0:handles.guidata.labels_plot_off+t1,j,k);
        set(handles.guidata.hpredicted(j),'XData',xpred(:),'YData',ypred(:));
      end
      if handles.guidata.label_state ~= 0,
        ts = sort([handles.label_t0,handles.guidata.ts(1)]);
        t0 = max(t0,ts(1));
        t1 = min(t1,ts(2)+1);
        xdata = handles.guidata.data.GetTrxValues('X1',handles.guidata.expi,handles.guidata.flies(1),t0:t1);
        ydata = handles.guidata.data.GetTrxValues('Y1',handles.guidata.expi,handles.guidata.flies(1),t0:t1);
        set(handles.guidata.hlabel_curr(1),'XData',xdata,'YData',ydata);
        if handles.guidata.label_state == -1,
          set(handles.guidata.hlabel_curr(1),'Color',handles.guidata.labelunknowncolor);
        else
          set(handles.guidata.hlabel_curr(1),'Color',handles.guidata.labelcolors(handles.guidata.label_state,:));
        end
      else
        set(handles.guidata.hlabel_curr(1),'XData',nan,'YData',nan);
      end

    end
  end
  
  if refresh_curr_prop,
    for propi = 1:numel(handles.guidata.perframepropis),
      v = handles.guidata.perframepropis(propi);
      if handles.guidata.ts(i) < handles.guidata.t0_curr || handles.guidata.ts(i) > handles.guidata.t1_curr,
        s = '';
      else
        perframedata = handles.guidata.data.GetPerFrameData1(handles.guidata.expi,handles.guidata.flies,v,handles.guidata.ts(i));
        s = sprintf('%.3f',perframedata);
      end
      if numel(handles.guidata.text_timeline_props) >= propi && ishandle(handles.guidata.text_timeline_props(propi)),
        set(handles.guidata.text_timeline_props(propi),'String',s);
      end
    end
  end
  
  %drawnow;
  
end


function [handles,success] = SetCurrentMovie(handles,expi)

success = false;

if expi == handles.guidata.expi,
  success = true;
  return;
end

% check that the current movie exists
if handles.guidata.data.ismovie,
  [moviefilename,timestamp] = handles.guidata.data.GetFile('movie',expi);
  if isinf(timestamp) && ~exist(moviefilename,'file'),
    uiwait(warndlg(sprintf('Movie file %s does not exist.',moviefilename),'Error setting movie'));
    return;
  end

  % close previous movie
  if ~isempty(handles.guidata.movie_fid) && ~isempty(fopen(handles.guidata.movie_fid)),
    if ~isempty(handles.guidata.movie_fid) && handles.guidata.movie_fid > 0,
      fclose(handles.guidata.movie_fid);
    end
  end

  % open new movie
  % try
  SetStatus(handles,'Opening movie...');
  if 1,
    [handles.guidata.readframe,handles.guidata.nframes,handles.guidata.movie_fid,handles.guidata.movieheaderinfo] = ...
      get_readframe_fcn(moviefilename);
  else
    fprintf('DEBUG!!!! USING GLOBAL VARIABLE WITH MOVIE READFRAME !!!DEBUG\n');
    global JLABEL__READFRAME;
    handles.guidata.readframe = JLABEL__READFRAME.readframe;
    handles.guidata.nframes = JLABEL__READFRAME.nframes;
    handles.guidata.movie_fid = JLABEL__READFRAME.movie_fid;
    handles.guidata.movieheaderinfo = JLABEL__READFRAME.movieheaderinfo;
  end
  im = handles.guidata.readframe(1);
  handles.guidata.movie_depth = size(im,3);
  handles.guidata.movie_width = size(im,2);
  handles.guidata.movie_height = size(im,1);
  handles.guidata.movie_filename = moviefilename;
  % catch ME,
  %   uiwait(warndlg(sprintf('Error opening movie file %s: %s',moviefilename,getReport(ME)),'Error setting movie'));
  %   ClearStatus(handles);
  %   return;
  % end
  
end

% number of flies
handles.guidata.nflies_curr = handles.guidata.data.nflies_per_exp(expi);

% choose flies
if handles.guidata.nflies_curr == 0,
  flies = [];
else
  flies = 1;
end

% load trx
[success,msg] = handles.guidata.data.PreLoad(expi,flies);
if ~success,
  uiwait(errordlg(sprintf('Error loading data for experiment %d: %s',expi,msg)));
  return;
end

% if no movie, then set limits
if ~handles.guidata.data.ismovie,
  maxx = max([handles.guidata.data.trx.x]+[handles.guidata.data.trx.a]*2);
  maxy = max([handles.guidata.data.trx.y]+[handles.guidata.data.trx.a]*2);
  handles.guidata.movie_height = ceil(maxy);
  handles.guidata.movie_width = ceil(maxx);
  handles.guidata.nframes = max([handles.guidata.data.trx.endframe]);

  % remove old grid
  delete(handles.guidata.bkgdgrid(ishandle(handles.guidata.bkgdgrid)));

  % grid width
  gridwidth = nanmean([handles.guidata.data.trx.a])*5;

  % create new grid
  handles.guidata.bkgdgrid = nan(2,numel(handles.guidata.axes_previews));
  xgrid = gridwidth/2:gridwidth:handles.guidata.movie_width;
  xgrid1 = [xgrid;xgrid;nan(1,numel(xgrid))];
  xgrid2 = [zeros(1,numel(xgrid));handles.guidata.movie_height+ones(1,numel(xgrid));nan(1,numel(xgrid))];
  ygrid = gridwidth/2:gridwidth:handles.guidata.movie_height;
  ygrid2 = [ygrid;ygrid;nan(1,numel(ygrid))];
  ygrid1 = [zeros(1,numel(ygrid));handles.guidata.movie_width+ones(1,numel(ygrid));nan(1,numel(ygrid))];
  for i = 1:numel(handles.guidata.axes_previews),
    holdstate = ishold(handles.guidata.axes_previews(i));
    hold(handles.guidata.axes_previews(i),'on');
    handles.guidata.bkgdgrid(1,i) = plot(handles.guidata.axes_previews(i),xgrid1(:),xgrid2(:),'--','Color',[.7,.7,.7],'LineWidth',.5,'HitTest','off');
    handles.guidata.bkgdgrid(2,i) = plot(handles.guidata.axes_previews(i),ygrid1(:),ygrid2(:),'--','Color',[.7,.7,.7],'LineWidth',.5,'HitTest','off');
    if ~holdstate,
      hold(handles.guidata.axes_previews(i),'off');
    end
      
  end
  
  % set axes colors to be white instead of black
  set(handles.guidata.axes_previews,'Color','w');
  
end

% set zoom radius
if isnan(handles.guidata.zoom_fly_radius(1)),
  handles.guidata.meana = nanmean([handles.guidata.data.trx.a]);
  handles.guidata.zoom_fly_radius = handles.guidata.meana*20 + [0,0];
end

% count the maximum number of flies in any frames
off = 1-min(handles.guidata.data.firstframes_per_exp{expi});
nflies_per_frame = zeros(1,max(handles.guidata.data.endframes_per_exp{expi}+off));
for fly = 1:handles.guidata.data.nflies_per_exp(expi),
  i0 = handles.guidata.data.firstframes_per_exp{expi}(fly)+off;
  i1 = handles.guidata.data.endframes_per_exp{expi}(fly)+off;
  nflies_per_frame(i0:i1) = nflies_per_frame(i0:i1) + 1;
end
maxnflies_curr = max(nflies_per_frame);

handles.guidata.expi = expi;

ClearStatus(handles);

% TODO: change hard-coded colormap
% update colors
handles.guidata.fly_colors = jet(handles.guidata.nflies_curr)*.7;
handles.guidata.fly_colors = handles.guidata.fly_colors(randperm(handles.guidata.nflies_curr),:);

% delete old fly current positions
if ~isempty(handles.guidata.hflies),
  delete(handles.guidata.hflies(ishandle(handles.guidata.hflies)));
  handles.guidata.hflies = [];
end
if ~isempty(handles.guidata.hflies_extra),
  delete(handles.guidata.hflies_extra(ishandle(handles.guidata.hflies_extra)));
  handles.guidata.hflies_extra = [];
end
if ~isempty(handles.guidata.hfly_markers),
  delete(handles.guidata.hfly_markers(ishandle(handles.guidata.hfly_markers)));
  handles.guidata.hfly_markers = [];
end

% update plotted trx handles, as number of flies will change
handles.guidata.hflies = nan(maxnflies_curr,numel(handles.guidata.axes_previews));
handles.guidata.hflies_extra = nan(maxnflies_curr,handles.guidata.nextra_markers,numel(handles.guidata.axes_previews));
handles.guidata.hfly_markers = nan(maxnflies_curr,numel(handles.guidata.axes_previews));
handles.guidata.idx2fly = zeros(1,maxnflies_curr);
handles.guidata.fly2idx = zeros(1,handles.guidata.nflies_curr);

for i = 1:numel(handles.guidata.axes_previews),
  % fly current positions
  for fly = 1:maxnflies_curr,
    handles.guidata.hflies(fly,i) = plot(handles.guidata.axes_previews(i),nan,nan,'-',...
      'color',handles.guidata.fly_colors(fly,:),'linewidth',3,...
      'ButtonDownFcn',@(hObject,eventdata) JLabel('fly_ButtonDownFcn',hObject,eventdata,guidata(hObject),fly,i));
    for j = 1:handles.guidata.nextra_markers,
      handles.guidata.hflies_extra(fly,j,i) = plot(handles.guidata.axes_previews(i),nan,nan,...
        'Marker',handles.guidata.flies_extra_marker{j},...
        'Color',handles.guidata.fly_colors(fly,:),'MarkerFaceColor',handles.guidata.fly_colors(fly,:),...
        'LineStyle',handles.guidata.flies_extra_linestyle{j},...
        'MarkerSize',handles.guidata.flies_extra_markersize(j),...
        'ButtonDownFcn',@(hObject,eventdata) JLabel('fly_ButtonDownFcn',hObject,eventdata,guidata(hObject),fly,i));
    end
    handles.guidata.hfly_markers(fly,i) = plot(handles.guidata.axes_previews(i),nan,nan,'*',...
      'color',handles.guidata.fly_colors(fly,:),'linewidth',3,...
      'ButtonDownFcn',@(hObject,eventdata) JLabel('fly_ButtonDownFcn',hObject,eventdata,guidata(hObject),fly,i),...
      'Visible','off');
  end
end

% set flies
handles = SetCurrentFlies(handles,flies,true,false);

% update slider steps, range
for i = 1:numel(handles.guidata.slider_previews),
  set(handles.guidata.slider_previews(i),'Min',1,'Max',handles.guidata.nframes,...
    'Value',1,...
    'SliderStep',[1/(handles.guidata.nframes-1),100/(handles.guidata.nframes-1)]);
end

% choose frame
for i = 1:numel(handles.guidata.axes_previews),
  handles = SetCurrentFrame(handles,i,handles.guidata.t0_curr,nan,true,false);
end

% update zoom
for i = 1:numel(handles.guidata.axes_previews),
  axis(handles.guidata.axes_previews(i),[.5,handles.guidata.movie_width+.5,.5,handles.guidata.movie_height+.5]);
end
for i = 1:numel(handles.guidata.axes_previews),
  zoom(handles.guidata.axes_previews(i),'reset');
end

% update plot
UpdatePlots(handles,'refresh_timeline_props',true,'refresh_timeline_selection',true);
ZoomInOnFlies(handles);

for h = handles.guidata.axes_timeline_labels,
  zoom(h,'reset');
end

% enable GUI components
EnableGUI(handles);

success = true;

function handles = UnsetCurrentMovie(handles)

% close previous movie
if ~isempty(handles.guidata.movie_fid) && ~isempty(fopen(handles.guidata.movie_fid)) && ...
    handles.guidata.movie_fid~=0,
  fclose(handles.guidata.movie_fid);
end

handles.guidata.expi = 0;
handles.guidata.flies = nan(1,handles.guidata.nflies_label);
handles.guidata.ts = zeros(1,numel(handles.guidata.axes_previews));
handles.guidata.label_state = 0;
handles.guidata.label_imp = [];
handles.guidata.nflies_curr = 0;
% delete old fly current positions
if ~isempty(handles.guidata.hflies),
  delete(handles.guidata.hflies(ishandle(handles.guidata.hflies)));
  handles.guidata.hflies = [];
end
if ~isempty(handles.guidata.hflies_extra),
  delete(handles.guidata.hflies_extra(ishandle(handles.guidata.hflies_extra)));
  handles.guidata.hflies_extra = [];
end
if ~isempty(handles.guidata.hfly_markers),
  delete(handles.guidata.hfly_markers(ishandle(handles.guidata.hfly_markers)));
  handles.guidata.hfly_markers = [];
end


% enable GUI components
EnableGUI(handles);


function i = GetPreviewPanelNumber(hObject)

i = regexp(get(get(hObject,'Parent'),'Tag'),'^panel_axes(\d+)$','tokens','once');
if isempty(i),
  warning('Could not find index of parent panel');
  i = 1;
else
  i = str2double(i{1});
end


% --- Executes on slider movement.
function slider_preview_Callback(hObject, eventdata, handles) %#ok<*DEFNU>
% hObject    handle to slider_preview (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% get slider value
% t = min(max(1,round(get(hObject,'Value'))),handles.guidata.nframes);
t = min(max(handles.guidata.t0_curr,round(get(hObject,'Value'))),handles.guidata.t1_curr);
set(hObject,'Value',t);
% which preview panel is this
i = GetPreviewPanelNumber(hObject);

% set current frame
SetCurrentFrame(handles,i,t,hObject);

function handles = SetCurrentFlies(handles,flies,doforce,doupdateplot)

if ~exist('doforce','var'),
  doforce = false;
end
if ~exist('doupdateplot','var'),
  doupdateplot = true;
end

[success,msg] = handles.guidata.data.PreLoad(handles.guidata.expi,flies);
if ~success,
  uiwait(waitdlg(sprintf('Error loading data for current set of flies: %s',msg)));
  return;
end

% same flies, return
if ~doforce && isempty(setdiff(flies,handles.guidata.flies)) && ...
    isempty(setdiff(handles.guidata.flies,flies)),
  return;
end

handles.guidata.flies = flies;

% frames these flies are both alive
handles.guidata.t0_curr = max(handles.guidata.data.GetTrxFirstFrame(handles.guidata.expi,handles.guidata.flies));
handles.guidata.t1_curr = min(handles.guidata.data.GetTrxEndFrame(handles.guidata.expi,handles.guidata.flies));

% form of labels for easier plotting:
% x, y positions of all labels
handles.guidata.labels_plot = struct;
n = handles.guidata.t1_curr-handles.guidata.t0_curr+1;
handles.guidata.labels_plot.im = zeros([1,n,3]);
handles.guidata.labels_plot.predicted_im = zeros([1,n,3]);
handles.guidata.labels_plot.suggest_xs = nan;
handles.guidata.labels_plot.error_xs = nan;
%handles.guidata.labels_plot.suggested_im = zeros([1,n,3]);
%handles.guidata.labels_plot.error_im = zeros([1,n,3]);
handles.guidata.labels_plot.x = nan(2,n,handles.guidata.data.nbehaviors,numel(handles.guidata.flies));
handles.guidata.labels_plot.y = nan(2,n,handles.guidata.data.nbehaviors,numel(handles.guidata.flies));
handles.guidata.labels_plot.predx = nan(2,n,handles.guidata.data.nbehaviors,numel(handles.guidata.flies));
handles.guidata.labels_plot.predy = nan(2,n,handles.guidata.data.nbehaviors,numel(handles.guidata.flies));
handles.guidata.labels_plot_off = 1-handles.guidata.t0_curr;
% set([handles.guidata.himage_timeline_manual,handles.guidata.himage_timeline_auto,...
%   handles.himage_timeline_error,handles.himage_timeline_suggest],...
%   'XData',[handles.guidata.t0_curr,handles.guidata.t1_curr]);
set([handles.guidata.himage_timeline_manual,handles.guidata.himage_timeline_auto],...
  'XData',[handles.guidata.t0_curr,handles.guidata.t1_curr]);

labelidxStruct = handles.guidata.data.GetLabelIdx(handles.guidata.expi,flies);
labelidx = labelidxStruct.vals;

prediction = handles.guidata.data.GetPredictedIdx(handles.guidata.expi,flies);
predictedidx = prediction.predictedidx;
scores = handles.guidata.data.NormalizeScores(prediction.scoresidx);
for flyi = 1:numel(flies),
  fly = flies(flyi);
  x = handles.guidata.data.GetTrxValues('X1',handles.guidata.expi,fly,handles.guidata.t0_curr:handles.guidata.t1_curr);
  y = handles.guidata.data.GetTrxValues('Y1',handles.guidata.expi,fly,handles.guidata.t0_curr:handles.guidata.t1_curr);
  for behaviori = 1:handles.guidata.data.nbehaviors
    idx = find(labelidx == behaviori);
    idx1 = min(idx+1,numel(x));
    handles.guidata.labels_plot.x(1,idx,behaviori,flyi) = x(idx);
    handles.guidata.labels_plot.x(2,idx,behaviori,flyi) = x(idx1);
    handles.guidata.labels_plot.y(1,idx,behaviori,flyi) = y(idx);
    handles.guidata.labels_plot.y(2,idx,behaviori,flyi) = y(idx1);
    
%     idx = find(predictedidx == behaviori);
    idx = find((predictedidx == behaviori) & ...
      (abs(scores)>handles.guidata.data.GetConfidenceThreshold(behaviori)));
    idx1 = min(idx+1,numel(x));
    handles.guidata.labels_plot.predx(1,idx,behaviori,flyi) = x(idx);
    handles.guidata.labels_plot.predx(2,idx,behaviori,flyi) = x(idx1);
    handles.guidata.labels_plot.predy(1,idx,behaviori,flyi) = y(idx);
    handles.guidata.labels_plot.predy(2,idx,behaviori,flyi) = y(idx1);
  end
end
handles = UpdateTimelineIms(handles);

% which interval we're currently within
handles.guidata.current_interval = [];

% update timelines
set(handles.guidata.himage_timeline_manual,'CData',handles.guidata.labels_plot.im);
axis(handles.axes_timeline_manual,[handles.guidata.t0_curr-.5,handles.guidata.t1_curr+.5,.5,1.5]);
% update zoom
for h = handles.guidata.axes_timeline_labels,
  zoom(h,'reset');
end

% update trx colors
for i = 1:numel(handles.guidata.axes_previews),
  for j = 1:numel(handles.guidata.flies),
    fly = handles.guidata.flies(j);
    set(handles.guidata.htrx(j,i),'Color',handles.guidata.fly_colors(fly,:));
  end
end

% Update colors for all other flies. 
inbounds = handles.guidata.data.firstframes_per_exp{handles.guidata.expi} <= handles.guidata.ts(i) & ...
  handles.guidata.data.endframes_per_exp{handles.guidata.expi} >= handles.guidata.ts(i);

for i = 1:numel(handles.guidata.axes_previews),
  for j = 1:numel(handles.guidata.idx2fly),
    fly = handles.guidata.idx2fly(j);
    if fly == 0 || ~inbounds(fly),
      continue;
    end
    set(handles.guidata.hflies(j,i),'Color',handles.guidata.fly_colors(fly,:));
    set(handles.guidata.hflies_extra(j,:,i),'Color',handles.guidata.fly_colors(fly,:),...
      'MarkerFaceColor',handles.guidata.fly_colors(fly,:));
  end
end

% status bar text
[~,expname] = myfileparts(handles.guidata.data.expdirs{handles.guidata.expi});
if numel(handles.guidata.flies) == 1,
  handles.guidata.status_bar_text = sprintf('%s, %s %d',expname,handles.guidata.data.targettype,handles.guidata.flies);
else
  handles.guidata.status_bar_text = [sprintf('%s, %d',expname,handles.guidata.data.targettype),sprintf(' %d',handles.guidata.flies)];
end

% make sure frame is within bounds
isset = handles.guidata.ts ~= 0;
ts = max(handles.guidata.t0_curr,min(handles.guidata.t1_curr,handles.guidata.ts));
ts(~isset) = 0;
for i = 1:numel(ts),
  if ts(i) ~= handles.guidata.ts(i),
    handles = SetCurrentFrame(handles,i,ts(i),nan);
    handles.guidata.ts(i) = ts(i);
  end
end

ClearStatus(handles);

% TODO: generalize to multiple flies
s = GetTargetInfo(handles,flies(1));
set(handles.text_selection_info,'String',s);

guidata(handles.figure_JLabel,handles);

if doupdateplot,
  UpdatePlots(handles,'refresh_timeline_props',true,'refresh_timeline_selection',true);
end

function handles = UpdateTimelineIms(handles)

% Note: this function directly accesses handles.guidata.data.labelidx,
% handles.guidata.data.predictedidx for speed, so make sure we've preloaded the
% right experiment, flies
% REMOVED!

% if handles.guidata.expi ~= handles.guidata.data.expi || ~all(handles.guidata.flies == handles.guidata.data.flies),
%   handles.guidata.data.Preload(handles.guidata.expi,handles.guidata.flies);
% end

handles.guidata.labels_plot.im(:) = 0;
labelidx = handles.guidata.data.GetLabelIdx(handles.guidata.expi,handles.guidata.flies);

for behaviori = 1:handles.guidata.data.nbehaviors
  idx = (labelidx.vals == behaviori) & labelidx.imp;
  curColor = handles.guidata.labelcolors(behaviori,:);
  for channel = 1:3,
    handles.guidata.labels_plot.im(1,idx,channel) = curColor(channel);
  end
  
  idx = (labelidx.vals == behaviori) & ~labelidx.imp;
  curColor = ShiftColor.decreaseIntensity(handles.guidata.labelcolors(behaviori,:));
  for channel = 1:3,
    handles.guidata.labels_plot.im(1,idx,channel) = curColor(channel);
  end
end

handles.guidata.labels_plot.predicted_im(:) = 0;
prediction= handles.guidata.data.GetPredictedIdx(handles.guidata.expi,handles.guidata.flies);
predictedidx = prediction.predictedidx;
scores = handles.guidata.data.NormalizeScores(prediction.scoresidx);

% Scores for the bottom row.
switch handles.guidata.bottomAutomatic
  case 'Validated'
    scores_bottom = handles.guidata.data.GetValidatedScores(handles.guidata.expi,handles.guidata.flies);
    scores_bottom = handles.guidata.data.NormalizeScores(scores_bottom);
  case 'Loaded'
    scores_bottom = handles.guidata.data.GetLoadedScores(handles.guidata.expi,handles.guidata.flies);
    scores_bottom = handles.guidata.data.NormalizeScores(scores_bottom);
  case 'Old'
    scores_bottom = handles.guidata.data.GetOldScores(handles.guidata.expi,handles.guidata.flies);
    scores_bottom = handles.guidata.data.NormalizeScores(scores_bottom);
  case 'Postprocessed'
    [scores_bottom,prediction_bottom] =  handles.guidata.data.GetPostprocessedScores(handles.guidata.expi,handles.guidata.flies);
    scores_bottom = handles.guidata.data.NormalizeScores(scores_bottom);
  case 'None'
    scores_bottom = zeros(size(scores));
  case 'Distance'
    dist = handles.guidata.data.GetDistance(handles.guidata.expi,handles.guidata.flies);
    scores_bottom = zeros(size(scores));
  otherwise
    warndlg('Undefined scores type to display for the bottom part of the automatic');
end

if ~(any(strcmp(handles.guidata.bottomAutomatic,{'Postprocessed','Distance'})))
prediction_bottom = zeros(size(scores_bottom));
prediction_bottom(scores_bottom>0) = 1;
prediction_bottom(scores_bottom<0) = 2;
end

idxBottomScores = ~isnan(scores_bottom);
bottomScoreNdx = ceil(scores_bottom(idxBottomScores)*31)+32;

for behaviori = 1:handles.guidata.data.nbehaviors

  idxScores = predictedidx == behaviori ;
  idxPredict = idxScores & ...
    (abs(scores)>handles.guidata.data.GetConfidenceThreshold(behaviori));
  for channel = 1:3,
    
      handles.guidata.labels_plot.predicted_im(1,idxPredict,channel) = handles.guidata.labelcolors(behaviori,channel);
      handles.guidata.labels_plot.predicted_im(2,idxPredict,channel) = handles.guidata.labelcolors(behaviori,channel);
      scoreNdx = ceil(scores(idxScores)*31)+32;
      handles.guidata.labels_plot.predicted_im(3,idxScores,channel) = handles.guidata.scorecolor(scoreNdx,channel,1);
      handles.guidata.labels_plot.predicted_im(4,idxScores,channel) = handles.guidata.scorecolor(scoreNdx,channel,1);
    
      % bottom row scores.
      if strcmp(handles.guidata.bottomAutomatic,'Distance'),
        handles.guidata.labels_plot.predicted_im(5:6,:,channel) = repmat(1-dist(:)',[2 1 1]);
        handles.guidata.labels_plot.predicted_im(5:6,isnan(dist),channel) = 0;
        
      else
        handles.guidata.labels_plot.predicted_im(5,idxBottomScores,channel) = handles.guidata.scorecolor(bottomScoreNdx,channel,1);
        handles.guidata.labels_plot.predicted_im(6,prediction_bottom==behaviori,channel) = ...
          handles.guidata.labelcolors(behaviori,channel);
      end
  end    
  
end

[error_t0s,error_t1s] = get_interval_ends(labelidx.vals ~= 0 & predictedidx ~= 0 & ...
  labelidx.vals ~= predictedidx);
error_t0s = error_t0s + handles.guidata.t0_curr - 1.5;
error_t1s = error_t1s + handles.guidata.t0_curr - 1.5;
handles.guidata.labels_plot.error_xs = reshape([error_t0s;error_t1s;nan(size(error_t0s))],[1,numel(error_t0s)*3]);
set(handles.guidata.htimeline_errors,'XData',handles.guidata.labels_plot.error_xs,...
  'YData',zeros(size(handles.guidata.labels_plot.error_xs))+1.5);
[suggest_t0s,suggest_t1s] = get_interval_ends(labelidx.vals == 0 & predictedidx ~= 0);
suggest_t0s = suggest_t0s + handles.guidata.t0_curr - 1.5;
suggest_t1s = suggest_t1s + handles.guidata.t0_curr - 1.5;
handles.guidata.labels_plot.suggest_xs = reshape([suggest_t0s;suggest_t1s;nan(size(suggest_t0s))],[1,numel(suggest_t0s)*3]);
set(handles.guidata.htimeline_suggestions,'XData',handles.guidata.labels_plot.suggest_xs,...
  'YData',zeros(size(handles.guidata.labels_plot.suggest_xs))+1.5);

[suggest_t0s,suggest_t1s] = get_interval_ends(handles.guidata.data.GetGTSuggestionIdx(handles.guidata.expi,handles.guidata.flies));
suggest_t0s = suggest_t0s + handles.guidata.t0_curr - 1.5;
suggest_t1s = suggest_t1s + handles.guidata.t0_curr - 1.5;
handles.guidata.labels_plot.suggest_gt = reshape([suggest_t0s;suggest_t1s;nan(size(suggest_t0s))],[1,numel(suggest_t0s)*3]);
set(handles.guidata.htimeline_gt_suggestions,'XData',handles.guidata.labels_plot.suggest_gt,...
  'YData',zeros(size(handles.guidata.labels_plot.suggest_gt))+1.5);

%{
%handles.guidata.labels_plot.suggested_im(:) = 0;
%for behaviori = 1:handles.guidata.data.nbehaviors
%  idx = handles.guidata.data.suggestedidx == behaviori;
%  for channel = 1:3,
%    handles.guidata.labels_plot.suggested_im(1,idx,channel) = handles.guidata.labelcolors(behaviori,channel);
%  end
%end
%handles.guidata.labels_plot.error_im(:) = 0;
%idx = handles.guidata.data.erroridx == 1;
%for channel = 1:3,
%  handles.guidata.labels_plot.error_im(1,idx,channel) = handles.guidata.correctcolor(channel);
%end
%idx = handles.guidata.data.erroridx == 2;
%for channel = 1:3,
%  handles.guidata.labels_plot.error_im(1,idx,channel) = handles.guidata.incorrectcolor(channel);
%end
%}

handles.guidata.labels_plot.isstart = ...
cat(2,labelidx.vals(1)~=0,...
labelidx.vals(2:end)~=0 & ...
labelidx.vals(1:end-1)~=labelidx.vals(2:end));


% set current frame
function handles = SetCurrentFrame(handles,i,t,hObject,doforce,doupdateplot)

if ~exist('doforce','var'),
  doforce = false;
end
if ~exist('doupdateplot','var'),
  doupdateplot = true;
end

t = round(t);

if t<handles.guidata.t0_curr || t>handles.guidata.t1_curr,
  fprintf('Current frame is out of range for the current fly');
  t = min(max(handles.guidata.t0_curr,round(pt(1,1))),handles.guidata.t1_curr);
end


% check for change
if doforce || handles.guidata.ts(i) ~= t,

  handles.guidata.ts(i) = t;
  
  % update labels
%   if handles.guidata.label_state < 0,
%     handles = SetLabelPlot(handles,min(handles.guidata.t1_curr,max(handles.guidata.t0_curr,t)),0);
%   elseif handles.guidata.label_state > 0,
%     handles = SetLabelPlot(handles,min(handles.guidata.t1_curr,max(handles.guidata.t0_curr,t)),handles.guidata.label_state);
%   end
  
  % update slider
  if hObject ~= handles.guidata.slider_previews(i),
    set(handles.guidata.slider_previews(i),'Value',t);
  end

  % update frame number edit box
  if hObject ~= handles.guidata.edit_framenumbers(i),
    set(handles.guidata.edit_framenumbers(i),'String',num2str(t));
  end
  
  % update selection
  if handles.guidata.selecting,
    handles.guidata.selected_ts(end) = t;
    UpdateSelection(handles);
  end
  
  guidata(handles.figure_JLabel,handles);

  % update plot
  if doupdateplot,
    UpdatePlots(handles,'axes',i);
  end
  
  % TODO: update timeline zoom
  for h = handles.guidata.axes_timeline_labels,
    zoom(h,'reset');
  end
  
%   % out of bounds for labeling? then turn off labeling
%   if (t < handles.guidata.t0_curr || t > handles.guidata.t1_curr),
%     if handles.guidata.label_state > 0,
%       set(handles.guidata.togglebutton_label_behaviors(handles.guidata.label_state),'Value',0);
%     elseif handles.guidata.label_state < 0,
%       set(handles.togglebutton_label_unknown,'Value',0);
%     end
%     handles.guidata.label_state = 0;
%     set([handles.guidata.togglebutton_label_behaviors,handles.togglebutton_label_unknown],'Enable','off');
%   else
%     set([handles.guidata.togglebutton_label_behaviors,handles.togglebutton_label_unknown],'Enable','on');
%   end

  
end

% --- Executes during object creation, after setting all properties.
function slider_preview_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD>
% hObject    handle to slider_preview (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --------------------------------------------------------------------
function pushtool_save_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to pushtool_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_file_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_file_editfiles_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_editfiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% if isfield(handles,'data'),
% %   [success,msg] = handles.guidata.data.UpdateStatusTable();
% %   if ~success,
% %     error(msg);
% %   end
%   params = {handles.guidata.data};
% else
%   params = {handles.guidata.configfilename};
%   if isfield(handles,'defaultpath'),
%     params(end+1:end+2) = {'defaultpath',handles.guidata.defaultpath};
%   end
% end
if ~isempty(handles.guidata.expi) && handles.guidata.expi > 0,
  oldexpdir = handles.guidata.data.expdirs{handles.guidata.expi};
else
  oldexpdir = '';
end

DisableGUI(handles);
[handles,success] = ...
  JLabelEditFiles('disableBehavior',true,'JLabelHandle',handles); %params{:});
ReEnableGUI(handles);

handles.guidata.data.SetStatusFn(@(s) SetStatusCallback(s,handles.figure_JLabel));
handles.guidata.data.SetClearStatusFn(@() ClearStatusCallback(handles.figure_JLabel));

handles.guidata.defaultpath = handles.guidata.data.defaultpath;
if ~success,
  guidata(hObject,handles);
  return;
end
 


% save needed if list has changed
handles = SetNeedSave(handles);

if ~isempty(oldexpdir) && ismember(oldexpdir,handles.guidata.data.expdirs),
  j = find(strcmp(oldexpdir,handles.guidata.data.expdirs),1);
  handles.guidata.expi = j;
else
  handles = UnsetCurrentMovie(handles);
  if handles.guidata.data.nexps > 0 && handles.guidata.data.expi == 0,
    handles = SetCurrentMovie(handles,1);
  else
    handles = SetCurrentMovie(handles,handles.guidata.data.expi);
  end
end

handles = UpdateGUIGroundTruthMode(handles);

guidata(hObject,handles);

function handles = UpdateMovies(handles)

function handles = SetNeedSave(handles)

handles.guidata.needsave = true;
set(handles.menu_file_save,'Enable','on');
set(handles.menu_file_save_labels,'Enable','on');

function handles = SetSaved(handles)

handles.guidata.needsave = false;
set(handles.menu_file_save,'Enable','off');
set(handles.menu_file_save_labels,'Enable','off');

% --------------------------------------------------------------------
function success = menu_file_save_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename,pathname] = uiputfile('*.mat','Save classifier',handles.guidata.data.classifierfilename);
if ~ischar(filename),
  success = false;
  return;
end
handles.guidata.data.classifierfilename = fullfile(pathname,filename);
SetStatus(handles,sprintf('Saving classifier to %s',handles.guidata.data.classifierfilename));
handles.guidata.data.SaveClassifier();
handles.guidata.data.SaveLabels();
handles.guidata.data.SaveGTLabels();
handles = SetSaved(handles);
ClearStatus(handles);
success = true;

% --------------------------------------------------------------------
function menu_file_exit_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

figure_JLabel_CloseRequestFcn(hObject, eventdata, handles);

% --------------------------------------------------------------------
function menu_edit_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_view_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_go_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function menu_edit_undo_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_undo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function [handles,success] = LoadConfig(handles,forceui)

if ~exist('forceui','var'),
  forceui = false;
end

% initialize output to success = false
success = false;

% get config file
havefilename = false;
if ~forceui && ~isempty(handles.guidata.configfilename),
  havefilename = true;
end

% default config file name
if isempty(handles.guidata.configfilename),
  defaultconfigfilename = fullfile(handles.guidata.defaultpath,'JLabelConfig.xml');
else
  defaultpath = myfileparts(handles.guidata.configfilename);
  if exist(defaultpath,'file'),
    handles.guidata.defaultpath = defaultpath;
  end
  defaultconfigfilename = handles.guidata.configfilename;
end

% loop until we have a valid config file
while true,

  if ~havefilename,
    
    if ~exist(defaultconfigfilename,'file'),
      defaultconfigfilename = handles.guidata.defaultpath;
    end
  
    % get from user
    [filename,pathname] = uigetfile('*.xml','Choose XML config file',defaultconfigfilename);
    
    % if cancel clicked, just return
    if ~ischar(filename),
      return;
    end
    
    handles.guidata.configfilename = fullfile(pathname,filename);

    % store path as default
    handles.guidata.defaultpath = pathname;

  end
  
  % make sure the file exists
  if ~exist(handles.guidata.configfilename,'file'),
    havefilename = false;
    uiwait(warndlg(sprintf('File %s does not exist',handles.guidata.configfilename),'Error reading config file'));
    continue;
  end
    
%   try
  [~,~,ext] = fileparts(handles.guidata.configfilename);
  if strcmp(ext,'.xml')
    JLabelHandle.guidata.configparams = ReadXMLConfigParams(handles.guidata.configfilename);
  elseif strcmp(ext,'.mat')
    JLabelHandle.guidata.configparams = load(handles.guidata.configfilename);
  else
    errordlg('Project file is not a valid');
  end
%   catch ME,
%     uiwait(warndlg(sprintf('Error reading configuration from file %s: %s',handles.guidata.configfilename,getReport(ME)),'Error reading config file'));
%     havefilename = false;
%     continue;
%   end
  
  % success -- break
  break;

end

success = true;

function handles = InitializeState(handles)

handles = LoadRC(handles);

% whether save is necessary
handles.guidata.needsave = false;

% initialize data structure
handles.guidata.data = JLabelData(handles.guidata.configfilename,...
  'defaultpath',handles.guidata.defaultpath,...
  'classifierfilename',handles.guidata.classifierfilename,...
  'setstatusfn',@(s) SetStatusCallback(s,handles.figure_JLabel),...
  'clearstatusfn',@() ClearStatusCallback(handles.figure_JLabel),...
  'cacheSize',handles.guidata.cacheSize);

% number of flies to label at a time
handles.guidata.nflies_label = 1;

% learned classifier
handles.guidata.classifier = [];

% currently shown experiment
handles.guidata.expi = 0;
% currently labeled flies
handles.guidata.flies = 1:handles.guidata.nflies_label;
% currently shown frame
handles.guidata.ts = 0;

% current behavior labeling state: nothing down
handles.guidata.label_state = 0;
handles.guidata.label_imp = [];

% number of flies for the current movie
handles.guidata.nflies_curr = 0;

% label colors
if isfield(handles.guidata.configparams,'behaviors') && ...
    isfield(handles.guidata.configparams.behaviors,'labelcolors'),
  labelcolors = handles.guidata.configparams.behaviors.labelcolors;
  if numel(labelcolors) >= 3*handles.guidata.data.nbehaviors,
    handles.guidata.labelcolors = reshape(labelcolors(1:3*handles.guidata.data.nbehaviors),[handles.guidata.data.nbehaviors,3]);
  else
    uiwait(warndlg('Error parsing label colors from config file, automatically assigning','Error parsing config label colors'));
    if isfield(handles.guidata.configparams,'labels') && ...
        isfield(handles.guidata.configparams.labels,'colormap'),
      cm = handles.guidata.configparams.labels.colormap;
    else
      cm = 'lines';
    end
    if ~exist(cm,'file'),
      cm = 'lines';
    end
%     try
      handles.guidata.labelcolors = eval(sprintf('%s(%d)',cm,handles.guidata.data.nbehaviors));
%     catch ME,
%       uiwait(warndlg(sprintf('Error using label colormap from config file: %s',getReport(ME)),'Error parsing config label colors'));
%       handles.guidata.labelcolors = lines(handles.guidata.data.nbehaviors);
%     end
  end
end
handles.guidata.labelunknowncolor = [0,0,0];
if isfield(handles.guidata.configparams,'behaviors') && ...
    isfield(handles.guidata.configparams.behaviors,'unknowncolor'),
  unknowncolor = handles.guidata.configparams.behaviors.unknowncolor;
  if ischar(unknowncolor),
    unknowncolor = str2double(strsplit(unknowncolor,','));
    handles.guidata.configparams.behaviors.unknowncolor = unknowncolor;
  end
  if numel(unknowncolor) >= 3,
    handles.guidata.labelunknowncolor = reshape(unknowncolor(1:3),[1,3]);
  else
    uiwait(warndlg('Error parsing unknown color from config file, automatically assigning','Error parsing config unknown colors'));
  end
end

handles.guidata.nextra_markers = 1;
if isfield(handles.guidata.configparams,'plot') && ...
    isfield(handles.guidata.configparams.plot,'trx') && ...
    isfield(handles.guidata.configparams.plot.trx,'nextra_markers'),
  handles.guidata.nextra_markers = handles.guidata.configparams.plot.trx.nextra_markers;
end

handles.guidata.flies_extra_markersize = repmat(12,[1,handles.guidata.nextra_markers]);
if isfield(handles.guidata.configparams,'plot') && ...
    isfield(handles.guidata.configparams.plot,'trx') && ...
    isfield(handles.guidata.configparams.plot.trx,'extra_markersize') && ...
    ~isempty(handles.guidata.configparams.plot.trx.extra_markersize),
  if ~ischar(handles.guidata.configparams.plot.trx.extra_markersize),
    extra_markersize = handles.guidata.configparams.plot.trx.extra_markersize;
  else
    tmp = regexp(handles.guidata.configparams.plot.trx.extra_markersize,',','split');
    extra_markersize = str2double(tmp);
    if any(isnan(extra_markersize)),
      warndlg(['Could not parse some entries of plot.trx.extra_markersize:',sprintf(' %s',tmp{isnan(extra_markersize)})],'Problem parsing plot.trx.extra_markersize');
      extra_markersize(isnan(extra_markersize)) = 12;
    end
  end
  if numel(extra_markersize) < handles.guidata.nextra_markers,
    warndlg('Number of extra marker size entries less than number of extra markers','Problem parsing plot.trx.extra_markersize');
  end
  for j = 1:handles.guidata.nextra_markers,
    handles.guidata.flies_extra_markersize(j) = extra_markersize(min(j,numel(extra_markersize)));
  end
end

handles.guidata.flies_extra_marker = repmat({'o'},[1,handles.guidata.nextra_markers]);
if isfield(handles.guidata.configparams,'plot') && ...
    isfield(handles.guidata.configparams.plot,'trx') && ...
    isfield(handles.guidata.configparams.plot.trx,'extra_marker') && ...
    ~isempty(handles.guidata.configparams.plot.trx.extra_marker),
  if ischar(handles.guidata.configparams.plot.trx.extra_marker),
    extra_marker = regexp(handles.guidata.configparams.plot.trx.extra_marker,',','split');
  else
    extra_marker = handles.guidata.configparams.plot.trx.extra_marker;
  end
  if numel(extra_marker) < handles.guidata.nextra_markers,
    warndlg('Number of extra marker entries less than number of extra markers','Problem parsing plot.trx.extra_marker');
    handles.guidata.flies_extra_marker = [extra_marker,...
      repmat({'None'},[1,handles.guidata.nextra_markers-numel(extra_marker)])];
  else
    handles.guidata.flies_extra_marker = extra_marker(1:handles.guidata.nextra_markers);
  end
end
handles.guidata.flies_extra_linestyle = repmat({'-'},[1,handles.guidata.nextra_markers]);
if isfield(handles.guidata.configparams,'plot') && ...
    isfield(handles.guidata.configparams.plot,'trx') && ...
    isfield(handles.guidata.configparams.plot.trx,'extra_linestyle') && ...
    ~isempty(handles.guidata.configparams.plot.trx.extra_linestyle),
  if ischar(handles.guidata.configparams.plot.trx.extra_linestyle),
    extra_linestyle = regexp(handles.guidata.configparams.plot.trx.extra_linestyle,',','split');
  else
    extra_linestyle = handles.guidata.configparams.plot.trx.extra_linestyle;
  end
  if numel(extra_linestyle) < handles.guidata.nextra_markers,
    warndlg('Number of extra linestyle entries less than number of extra markers','Problem parsing plot.trx.extra_linestyle');
    handles.guidata.flies_extra_linestyle = [extra_linestyle,...
      repmat({'None'},[1,handles.guidata.nextra_markers-numel(extra_linestyle)])];
  else
    handles.guidata.flies_extra_linestyle = extra_linestyle(1:handles.guidata.nextra_markers);
  end  
end

for channel = 1:3
  midValue = handles.guidata.labelunknowncolor(channel);
  startValue = handles.guidata.labelcolors(2,channel);
  endValue = handles.guidata.labelcolors(1,channel);
  handles.guidata.scorecolor(1:32,channel,1) = (midValue-startValue)*(0:31)/31+startValue;
  handles.guidata.scorecolor(32:63,channel,1) = (endValue-midValue)*(0:31)/31+midValue;
end
for ndx = 1:63
  handles.guidata.scorecolor(ndx,:,2) = ShiftColor.shiftColorFwd(handles.guidata.scorecolor(ndx,:,1));
  handles.guidata.scorecolor(ndx,:,3) = ShiftColor.shiftColorBkwd(handles.guidata.scorecolor(ndx,:,1));  
end

handles.guidata.correctcolor = [0,.7,0];
handles.guidata.incorrectcolor = [.7,.7,0];
handles.guidata.suggestcolor = [0,.7,.7];

handles.guidata.selection_color = [1,.6,0];
handles.guidata.selection_alpha = .5;

% color for showing which labels are being plotted
handles.guidata.emphasiscolor = [.7,.7,0];
handles.guidata.unemphasiscolor = [1,1,1];

% create buttons for each label
handles = CreateLabelButtons(handles);

% timeline properties
handles.guidata.timeline_prop_remove_string = '<html><body><i>Remove</i></body></html>';
handles.guidata.timeline_prop_help_string = '<html><body><i>Help</i></body></html>';
handles.guidata.timeline_prop_options = ...
  {handles.guidata.timeline_prop_remove_string,...
  handles.guidata.timeline_prop_help_string};

if ~isempty(handles.guidata.data.allperframefns)
  for i = 1:numel(handles.guidata.data.allperframefns),
    handles.guidata.timeline_prop_options{end+1} = handles.guidata.data.allperframefns{i};
  end
  handles.guidata.d = handles.guidata.data.allperframefns(1);
  handles.guidata.perframepropis = 1;
  set(handles.timeline_label_prop1,'String',handles.guidata.timeline_prop_options,'Value',3);
  handles.guidata.timeline_data_ylims = nan(2,numel(handles.guidata.data.allperframefns));
end

% Setup the popup menu for bottom row of the automatic timeline.
bottomRowTypes = get(handles.automaticTimelineBottomRowPopup,'String');
set(handles.automaticTimelineBottomRowPopup,'Value', ...
  find(strcmp(bottomRowTypes,handles.guidata.bottomAutomatic)));
set(handles.automaticTimelinePredictionLabel,'FontSize',10);
set(handles.automaticTimelineScoresLabel,'FontSize',10);
set(handles.automaticTimelineBottomRowPopup,'FontSize',10);

% maximum distance squared in fraction of axis to change frames when
% clicking on preview window
handles.guidata.max_click_dist_preview = .005^2;

% zoom state
handles.guidata.preview_zoom_mode = 'follow_fly';
handles.guidata.zoom_fly_radius = nan(1,2);
handles.guidata.menu_view_zoom_options = findall(handles.menu_view_zoom,'Type','uimenu');
set(handles.guidata.menu_view_zoom_options,'Checked','off');
set(handles.menu_view_zoom_keep_target_in_view,'Checked','on');

% last clicked object
handles.guidata.selection_t0 = nan;
handles.guidata.selection_t1 = nan;
handles.guidata.selected_ts = nan(1,2);
handles.guidata.buttondown_t0 = nan;
handles.guidata.buttondown_axes = nan;
set([handles.pushbutton_playselection,handles.pushbutton_clearselection],'Enable','off');

% not selecting
handles.guidata.selecting = false;
set(handles.togglebutton_select,'Value',0);

% initialize nextjump obj;
handles.guidata.NJObj = NextJump();
handles.guidata.NJObj.SetSeekBehaviorsGo(1:handles.guidata.data.nbehaviors);
handles.guidata.NJObj.SetPerframefns(handles.guidata.data.allperframefns);
if isfield(handles.guidata.rc,'navPreferences')
  handles.guidata.NJObj.SetState(handles.guidata.rc.navPreferences);
end

% initialize labels for navigation
SetJumpGoMenuLabels(handles)

% label shortcuts
if numel(handles.guidata.label_shortcuts) ~= 2*handles.guidata.data.nbehaviors + 1,
  if handles.guidata.data.nbehaviors == 2,
    handles.guidata.label_shortcuts = {'z','a','x','s','c'}';
  else
    handles.guidata.label_shortcuts = cellstr(num2str((1:2*handles.guidata.data.nbehaviors+1)'));
  end
end

% play/stop
handles.guidata.hplaying = nan;
%handles.guidata.play_FPS = 2;

%handles.guidata.traj_nprev = 25;
%handles.guidata.traj_npost = 25;

% whether to show trajectories
set(handles.menu_view_plottracks,'Checked','on');
handles.doplottracks = true;

% bookmarked clips windows
handles.guidata.bookmark_windows = [];

% whether to plot manual labels or automatic labels
handles.guidata.plot_labels_manual = true;
handles.guidata.plot_labels_automatic = false;
set(handles.menu_view_plot_labels_manual,'Checked','on');
set(handles.menu_view_plot_labels_automatic,'Checked','off');

buttonNames = {'pushbutton_train','pushbutton_predict',...
              'togglebutton_select','pushbutton_clearselection',...
              'pushbutton_playselection','pushbutton_playstop',...
              'similarFramesButton','bagButton'};
  
for buttonNum = 1:numel(buttonNames)
  SetButtonImage(handles.(buttonNames{buttonNum}));
end

set(handles.similarFramesButton,'Enable','off');
handles.guidata.doFastUpdates = true;

SetGUIModeMenuChecks(handles);

function SetGUIModeMenuChecks(handles)

if handles.guidata.data.IsGTMode(),
  return;
end

% gui mode
guimode_menus = [handles.menu_edit_guimode_advancedtraining,...
  handles.menu_edit_guimode_basictraining];
if handles.guidata.data.IsAdvancedMode(),
  h = handles.menu_edit_guimode_advancedtraining;
else
  h = handles.menu_edit_guimode_basictraining;
end
set(guimode_menus,'Checked','off');
set(h,'Checked','on');


function SetJumpGoMenuLabels(handles)

set(handles.menu_go_forward_X_frames,'Label',sprintf('Forward %d frames (down arrow)',handles.guidata.nframes_jump_go));
set(handles.menu_go_back_X_frames,'Label',sprintf('Back %d frames (up arrow)',handles.guidata.nframes_jump_go));
jumpType = handles.guidata.NJObj.GetCurrentType();
set(handles.menu_go_next_automatic_bout_start,'Label',...
  sprintf('Next %s bout start (shift + right arrow)',jumpType));
set(handles.menu_go_previous_automatic_bout_end,'Label',...
  sprintf('Next %s bout end (shift + left arrow)',jumpType));

% create buttons for each label
function handles = CreateLabelButtons(handles)

% get positions of stuff
set(handles.panel_labelbuttons,'Units','pixels');
panel_pos = get(handles.panel_labelbuttons,'Position');
select_pos = get(handles.panel_select,'Position');
set(handles.togglebutton_label_behavior1,'Units','pixels');
button1_pos = get(handles.togglebutton_label_behavior1,'Position');
set(handles.togglebutton_label_unknown,'Units','pixels');
unknown_button_pos = get(handles.togglebutton_label_unknown,'Position');
out_border_y = unknown_button_pos(2);
out_border_x = unknown_button_pos(1);
in_border_y = button1_pos(2) - (unknown_button_pos(2)+unknown_button_pos(4));
button_width = button1_pos(3);
button_height = button1_pos(4);

% calculate new height for the panel

if ~handles.guidata.data.IsAdvancedMode();
new_panel_height = 2*out_border_y + (handles.guidata.data.nbehaviors+1)*button_height + ...
  handles.guidata.data.nbehaviors*in_border_y;
else
new_panel_height = 2*out_border_y + (2*handles.guidata.data.nbehaviors+1)*button_height + ...
  2*handles.guidata.data.nbehaviors*in_border_y;
end
% update panel position
panel_top = panel_pos(2)+panel_pos(4);
new_panel_pos = [panel_pos(1),panel_top-new_panel_height,panel_pos(3),new_panel_height];
set(handles.panel_labelbuttons,'Position',new_panel_pos);
dy_label_select = panel_pos(2) - select_pos(2) - select_pos(4);
new_select_pos = [select_pos(1),new_panel_pos(2)-select_pos(4)-dy_label_select,select_pos(3:4)];
set(handles.panel_select,'Position',new_select_pos);

% move unknown button to the bottom
new_unknown_button_pos = [unknown_button_pos(1),out_border_y,unknown_button_pos(3),button_height];
set(handles.togglebutton_label_unknown,'Position',new_unknown_button_pos);

% list of buttons
handles.guidata.togglebutton_label_behaviors = nan(1,2*handles.guidata.data.nbehaviors);

% update first button
if handles.guidata.data.IsAdvancedMode()
  new_button1_pos = [out_border_x,new_panel_height-out_border_y-button_height,button_width,button_height];
  set(handles.togglebutton_label_behavior1,...
    'String',sprintf('Important %s',handles.guidata.data.labelnames{1}),...
    'ForegroundColor','w','Units','pixels','FontUnits','pixels','FontSize',14,...
    'FontWeight','bold','BackgroundColor',handles.guidata.labelcolors(1,:),...
    'Position',new_button1_pos,...
    'UserData',1);
  handles.guidata.togglebutton_label_behaviors(1) = handles.togglebutton_label_behavior1;
  SetButtonImage(handles.togglebutton_label_behavior1);
  pos = [out_border_x,new_panel_height-out_border_y-2*button_height-in_border_y,button_width,button_height];
  handles.guidata.togglebutton_label_behaviors(2) = uicontrol('Style','togglebutton',...
    'String',sprintf('%s',handles.guidata.data.labelnames{1}),...
    'ForegroundColor','w','Units','pixels','FontUnits','pixels','FontSize',14,...
    'FontWeight','bold','BackgroundColor',ShiftColor.decreaseIntensity(handles.guidata.labelcolors(1,:)),...
    'Parent',handles.panel_labelbuttons,...
    'Callback',get(handles.togglebutton_label_behavior1,'Callback'),...
    'Position',pos,'Tag',sprintf('togglebutton_label_normbehavior1'),...
    'UserData',2);
  SetButtonImage(handles.guidata.togglebutton_label_behaviors(2));
else
  pos = [out_border_x,new_panel_height-out_border_y-button_height,button_width,button_height];
  set(handles.togglebutton_label_behavior1,...
    'String',sprintf('%s',handles.guidata.data.labelnames{1}),...
    'ForegroundColor','w','Units','pixels','FontUnits','pixels','FontSize',14,...
    'FontWeight','bold','BackgroundColor',handles.guidata.labelcolors(1,:),...
    'Position',pos,...
    'UserData',1);
  handles.guidata.togglebutton_label_behaviors(1) = handles.togglebutton_label_behavior1;
  SetButtonImage(handles.guidata.togglebutton_label_behaviors(1));
end

  

% create the rest of the buttons
for i = 2:handles.guidata.data.nbehaviors,
  if handles.guidata.data.IsAdvancedMode()
    pos = [out_border_x,new_panel_height-out_border_y-button_height*(2*i-1)-in_border_y*(2*i-2),...
      button_width,button_height];
    handles.guidata.togglebutton_label_behaviors(2*i-1) = ...
      uicontrol('Style','togglebutton','String',sprintf('Important %s',handles.guidata.data.labelnames{i}),...
      'ForegroundColor','w','Units','pixels','FontUnits','pixels','FontSize',14,...
      'FontWeight','bold','BackgroundColor',handles.guidata.labelcolors(i,:),...
      'Position',pos,...
      'Callback',get(handles.togglebutton_label_behavior1,'Callback'),...
      'Parent',handles.panel_labelbuttons,...
      'Tag',sprintf('togglebutton_label_behavior%d',i),...
      'UserData',2*i-1);
    SetButtonImage(handles.guidata.togglebutton_label_behaviors(2*i-1));
    pos = [out_border_x,new_panel_height-out_border_y-button_height*(2*i)-in_border_y*(2*i-1),...
      button_width,button_height];
    handles.guidata.togglebutton_label_behaviors(2*i) = ...
      uicontrol('Style','togglebutton','String',sprintf('%s',handles.guidata.data.labelnames{i}),...
      'ForegroundColor','w','Units','pixels','FontUnits','pixels','FontSize',14,...
      'FontWeight','bold','BackgroundColor',ShiftColor.decreaseIntensity(handles.guidata.labelcolors(i,:)),...
      'Position',pos,...
      'Callback',get(handles.togglebutton_label_behavior1,'Callback'),...
      'Parent',handles.panel_labelbuttons,...
      'Tag',sprintf('togglebutton_label_normbehavior%d',i),...
      'UserData',2*i);
    SetButtonImage(handles.guidata.togglebutton_label_behaviors(2*i));
  else
    pos = [out_border_x,new_panel_height-out_border_y-button_height*i-in_border_y*(i-1),...
      button_width,button_height];
    handles.guidata.togglebutton_label_behaviors(2*i-1) = ...
      uicontrol('Style','togglebutton','String',sprintf('%s',handles.guidata.data.labelnames{i}),...
      'ForegroundColor','w','Units','pixels','FontUnits','pixels','FontSize',14,...
      'FontWeight','bold','BackgroundColor',handles.guidata.labelcolors(i,:),...
      'Position',pos,...
      'Callback',get(handles.togglebutton_label_behavior1,'Callback'),...
      'Parent',handles.panel_labelbuttons,...
      'Tag',sprintf('togglebutton_label_normbehavior%d',i),...
      'UserData',2*i-1);
    SetButtonImage(handles.guidata.togglebutton_label_behaviors(2*i-1));
  end
end

% set props for unknown button
set(handles.togglebutton_label_unknown,...
  'String','Unknown',...
  'ForegroundColor','w','Units','pixels','FontUnits','pixels','FontSize',14,...
  'FontWeight','bold','BackgroundColor',handles.guidata.labelunknowncolor,...
  'UserData',-1);
SetButtonImage(handles.togglebutton_label_unknown);


handles.guidata.GUIAdvancedMode = handles.guidata.data.IsAdvancedMode();

  
function EnableGUI(handles)

% these controls require a movie to currently be open
h = [handles.contextmenu_timeline_manual_timeline_options,...
    handles.guidata.togglebutton_label_behaviors(:)',...
    handles.togglebutton_label_unknown,...
    handles.guidata.menu_view_zoom_options(:)'];
h = h(~isnan(h));
hp = [handles.guidata.panel_previews(:)',...
  handles.panel_timelines,...
  handles.panel_learn];
if handles.guidata.expi >= 1 && handles.guidata.expi <= handles.guidata.data.nexps,
  set(h,'Enable','on');
  set(hp,'Visible','on');
else
  set(h,'Enable','off');
  set(hp,'Visible','off');
end

% whether we need to save
if handles.guidata.needsave,
  set(handles.menu_file_save,'Enable','on');
else
  set(handles.menu_file_save,'Enable','off');
end

set(handles.menu_file_save_project,'Enable','off');

function handles = LoadRC(handles)

% rc file name
if isdeployed,
  handles.guidata.rcfilename = deployedRelative2Global('.JLabelrc.mat');
else
  handles.guidata.rcfilename = fullfile(myfileparts(mfilename('fullpath')),'.JLabelrc.mat');
end
handles.guidata.rc = struct;
if exist(handles.guidata.rcfilename,'file'),
%   try
    handles.guidata.rc = load(handles.guidata.rcfilename);
%   catch ME,
%     warning('Error loading rc file %s: %s',handles.guidata.rcfilename,getReport(ME));
%   end
end
% try
  if isfield(handles.guidata.rc,'defaultpath'),
    handles.guidata.defaultpath = handles.guidata.rc.defaultpath;
    if ~isempty(handles.guidata.data),
      handles.guidata.data.SetDefaultPath(handles.guidata.defaultpath);
    end
  end
  if isfield(handles.guidata.rc,'figure_JLabel_Position_px'),
    pos = handles.guidata.rc.figure_JLabel_Position_px;
    set(handles.figure_JLabel,'Units','pixels');
    % TODO: remove this once resizing is implemented
    pos0 = get(handles.figure_JLabel,'Position');
    pos(3:4) = pos0(3:4);
    set(handles.figure_JLabel,'Position',pos);
  end
  if isfield(handles.guidata.rc,'timeline_nframes'),
    handles.guidata.timeline_nframes = handles.guidata.rc.timeline_nframes;
  else
    handles.guidata.timeline_nframes = 250;
  end
  if isfield(handles.guidata.rc,'nframes_jump_go')
    handles.guidata.nframes_jump_go = handles.guidata.rc.nframes_jump_go;
  else
    handles.guidata.nframes_jump_go = 30;
  end
  
  if isfield(handles.guidata.rc,'label_shortcuts'),
    handles.guidata.label_shortcuts = handles.guidata.rc.label_shortcuts;
  else
    handles.guidata.label_shortcuts = [];
  end

  %output avi options
  
  % compression: scheme for compression for output avis
  if isfield(handles.guidata.rc,'outavi_compression'),
    handles.guidata.outavi_compression = handles.guidata.rc.outavi_compression;
  else
    handles.guidata.outavi_compression = 'None';
  end
  % outavi_fps: output frames per second
  if isfield(handles.guidata.rc,'outavi_fps'),
    handles.guidata.outavi_fps = handles.guidata.rc.outavi_fps;
  else
    handles.guidata.outavi_fps = 15;
  end
  % outavi_quality: output quality
  if isfield(handles.guidata.rc,'outavi_quality'),
    handles.guidata.outavi_quality = handles.guidata.rc.outavi_quality;
  else
    handles.guidata.outavi_quality = 95;
  end
  % useVideoWriter: whether to use videowriter class
  if isfield(handles.guidata.rc,'useVideoWriter'),
    handles.guidata.useVideoWriter = handles.guidata.rc.useVideoWriter > 0;
  else
    handles.guidata.useVideoWriter = exist('VideoWriter','file') > 0;
  end
  
  % preview options
  
  % playback speed
  if isfield(handles.guidata.rc,'play_FPS'),
    handles.guidata.play_FPS = handles.guidata.rc.play_FPS;
  else
    handles.guidata.play_FPS = 2;
  end
  
  if isfield(handles.guidata.rc,'traj_nprev'),
    handles.guidata.traj_nprev = handles.guidata.rc.traj_nprev;
  else
    handles.guidata.traj_nprev = 25;
  end
  
  if isfield(handles.guidata.rc,'traj_npost'),
    handles.guidata.traj_npost = handles.guidata.rc.traj_npost;
  else
    handles.guidata.traj_npost = 25;
  end
  
  if isfield(handles.guidata.rc,'bottomAutomatic')
    handles.guidata.bottomAutomatic = handles.guidata.rc.bottomAutomatic;
  else
    handles.guidata.bottomAutomatic = 'None';
  end
  
  % cache size
  if isfield(handles.guidata.rc,'cacheSize'),
    handles.guidata.cacheSize = handles.guidata.rc.cacheSize;
  else
    handles.guidata.cacheSize = 4000;
  end
  
% catch ME,
%   warning('Error loading RC file: %s',getReport(ME));  
% end

function handles = SaveRC(handles)

% try
  if isempty(handles.guidata.rcfilename),
    handles.guidata.rcfilename = fullfile(myfileparts(which('JLabel')),'.JLabelrc.mat');
  end
  
  rc = handles.guidata.rc;
  
  if ~isempty(handles.guidata.data),
    rc.defaultpath = handles.guidata.data.defaultpath;
  elseif ~isempty(handles.guidata.defaultpath),
    rc.defaultpath = handles.guidata.defaultpath;
  end
  rc.timeline_nframes = handles.guidata.timeline_nframes;
  
  set(handles.figure_JLabel,'Units','pixels');
  rc.figure_JLabel_Position_px = get(handles.figure_JLabel,'Position');
  
  rc.nframes_jump_go = handles.guidata.nframes_jump_go;
  
  % label shortcuts
  if ~isempty(handles.guidata.label_shortcuts),
    rc.label_shortcuts = handles.guidata.label_shortcuts;
  end
  
  
  %output avi options
  
  % compression: scheme for compression for output avis
  rc.outavi_compression = handles.guidata.outavi_compression;
  % outavi_fps: output frames per second
  rc.outavi_fps = handles.guidata.outavi_fps;
  % outavi_quality: output frames per second
  rc.outavi_quality = handles.guidata.outavi_quality;
  % useVideoWriter: whether to use videowriter class
  rc.useVideoWriter = handles.guidata.useVideoWriter;
  
  % preview options
  
  % playback speed
  rc.play_FPS = handles.guidata.play_FPS;
  
  rc.traj_nprev = handles.guidata.traj_nprev;
  rc.traj_npost = handles.guidata.traj_npost;
  
  % navigation preferences
  rc.navPreferences = handles.guidata.NJObj.GetState();
  rc.bottomAutomatic = handles.guidata.bottomAutomatic;
  
  % cache size
  rc.cacheSize = handles.guidata.cacheSize;
  
  save(handles.guidata.rcfilename,'-struct','rc');

% catch ME,
%   warning('Error saving RC file: %s',getReport(ME));
% end


% --- Executes when user attempts to close figure_JLabel.
function figure_JLabel_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure_JLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
%delete(hObject);

delete(handles.guidata.cache_thread);
handles.guidata.cache_thread = [];
UpdatePlots(handles,'CLEAR');
%clear functions  % BJA: need to clear persistent vars in UpdatePlots
if ispc, pause(.1); end
cachefilename = ['cache-' num2str(feature('getpid')) '.dat'];
if exist(cachefilename,'file'),
  delete(cachefilename);
end

% check if we need to save
if handles.guidata.needsave,
  res = questdlg('Save classifier and labels before quitting?','Save?','Yes','No','Cancel','Yes');
  if strcmpi(res,'Yes'),
    success = menu_file_save_Callback(hObject, eventdata, handles);
    if ~success,
      return;
    end
    handles = guidata(hObject);
  elseif strcmpi(res,'Cancel'),
    return;
  end
end

if handles.guidata.data.NeedSaveProject(),
  res = questdlg(['Current window features do not match the ones in the project file.'...
      'Update the project file with the current window features?'],...
      'Update?','Yes','No','Cancel','Yes');
  if strcmpi(res,'Yes')
    menu_file_save_project_Callback(hObject,eventdata,handles);
  elseif strcmpi(res,'Cancel');
    return;
  end
    
    
end  

if ~isempty(handles.guidata.movie_fid) && ...
    handles.guidata.movie_fid > 1 && ~isempty(fopen(handles.guidata.movie_fid)),
  fclose(handles.guidata.movie_fid);
  handles.guidata.movie_fid = [];
end
% try
  % turn off zooming
  zoom(handles.figure_JLabel,'off');
% catch %#ok<CTCH>
% end
% SWITCH THIS
for ndx = 1:numel(handles.guidata.open_peripherals)
  if ishandle(handles.guidata.open_peripherals(ndx)),
    delete(handles.guidata.open_peripherals(ndx));
  end
end

if true,
  SaveRC(handles);
  delete(handles.figure_JLabel);
else
  uiresume(handles.figure_JLabel); %#ok<UNRCH>
end


% --------------------------------------------------------------------
function toggletool_zoomin_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to toggletool_zoomin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function toggletool_zoomin_OnCallback(hObject, eventdata, handles)
% hObject    handle to toggletool_zoomin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set([handles.toggletool_zoomout,handles.toggletool_pan],'State','off');
pan(handles.figure_JLabel,'off');
set(handles.guidata.hzoom,'Direction','in','Enable','on');


% --------------------------------------------------------------------
function toggletool_zoomin_OffCallback(hObject, eventdata, handles)
% hObject    handle to toggletool_zoomin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.guidata.hzoom,'Enable','off');


% --------------------------------------------------------------------
function toggletool_zoomout_OffCallback(hObject, eventdata, handles)
% hObject    handle to toggletool_zoomout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.guidata.hzoom,'Enable','off');

% --------------------------------------------------------------------
function toggletool_zoomout_OnCallback(hObject, eventdata, handles)
% hObject    handle to toggletool_zoomout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set([handles.toggletool_zoomin,handles.toggletool_pan],'State','off');
pan(handles.figure_JLabel,'off');
set(handles.guidata.hzoom,'Direction','out','Enable','on');


% --------------------------------------------------------------------
function toggletool_zoomout_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to toggletool_zoomout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function toggletool_pan_OnCallback(hObject, eventdata, handles)
% hObject    handle to toggletool_pan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set([handles.toggletool_zoomin,handles.toggletool_zoomout],'State','off');
zoom(handles.figure_JLabel,'off');
pan(handles.figure_JLabel,'on');

% --------------------------------------------------------------------
function toggletool_pan_OffCallback(hObject, eventdata, handles)
% hObject    handle to toggletool_pan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pan(handles.figure_JLabel,'off');


% --- Executes on button press in togglebutton_label_behavior1.
function togglebutton_label_behavior1_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_label_behavior1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton_label_behavior1
buttonNum = get(hObject,'UserData');
behaviori = ceil(buttonNum/2);
isImportant = mod(buttonNum,2);

if get(hObject,'Value'),
  % toggle on, label pen is down.
  
  handles.guidata.label_state = behaviori;
  handles.guidata.label_imp = isImportant;
  handles.label_t0 = handles.guidata.ts(1);
  
  % set everything else to off
  for j = 1:2*handles.guidata.data.nbehaviors,
    if j == buttonNum || isnan(handles.guidata.togglebutton_label_behaviors(j)),
      continue;
    end
    set(handles.guidata.togglebutton_label_behaviors(j),'Value',0,'Enable','off');
  end
  set(handles.togglebutton_label_unknown,'Value',0,'Enable','off');

  curColor = handles.guidata.labelcolors(behaviori,:);
  if ~isImportant, curColor = ShiftColor.decreaseIntensity(curColor); end
  set(handles.guidata.htimeline_label_curr,'XData',handles.label_t0 + [-.5,-.5,.5,.5,-.5],...
    'FaceColor',curColor);
  % set the current frame to be labeled
  %handles.lastframe_labeled = [];
  %handles = SetLabelPlot(handles,min(handles.guidata.t1_curr,max(handles.guidata.t0_curr,handles.guidata.ts(1))),behaviori);
  
  UpdatePlots(handles,...
     'refreshim',false,'refreshflies',true,'refreshtrx',false,'refreshlabels',true,...
     'refresh_timeline_manual',true,...
     'refresh_timeline_auto',false,...
     'refresh_timeline_suggest',false,...
     'refresh_timeline_error',true,...
     'refresh_timeline_xlim',false,...
     'refresh_timeline_hcurr',false,...
     'refresh_timeline_props',false,...
     'refresh_timeline_selection',false,...
     'refresh_curr_prop',false);

   set(handles.menu_file,'enable','off');
   set(handles.menu_edit,'enable','off');
   set(handles.menu_go,'enable','off');
   set(handles.menu_classifier,'enable','off');
   set(handles.pushbutton_train,'Enable','off');
   
else % label pen is up.
  
  
  if handles.guidata.ts(1) <= handles.label_t0,
    t0 = handles.guidata.ts(1);
    t1 = handles.label_t0;
  else
    t0 = handles.label_t0;
    t1 = handles.guidata.ts(1);
  end
  t0 = min(handles.guidata.t1_curr,max(handles.guidata.t0_curr,t0));
  t1 = min(handles.guidata.t1_curr,max(handles.guidata.t0_curr,t1));
  handles = SetLabelPlot(handles,t0,t1,handles.guidata.label_state,handles.guidata.label_imp);

  handles.guidata.label_state = 0;
  handles.guidata.label_imp = [];
  handles.label_t0 = [];
  set(handles.guidata.htimeline_label_curr,'XData',nan(1,5));
  UpdatePlots(handles,...
    'refreshim',false,'refreshflies',true,'refreshtrx',false,'refreshlabels',true,...
    'refresh_timeline_manual',true,...
    'refresh_timeline_auto',false,...
    'refresh_timeline_suggest',false,...
    'refresh_timeline_error',true,...
    'refresh_timeline_xlim',false,...
    'refresh_timeline_hcurr',false,...
    'refresh_timeline_props',false,...
    'refresh_timeline_selection',false,...
    'refresh_curr_prop',false);
  
%   handles.guidata.data.StoreLabels();
  for j = 1:2*handles.guidata.data.nbehaviors,
    if isnan(handles.guidata.togglebutton_label_behaviors(j)), continue; end
    set(handles.guidata.togglebutton_label_behaviors(j),'Value',0,'Enable','on');
  end
  set(handles.togglebutton_label_unknown,'Value',0,'Enable','on');
  %set(handles.guidata.togglebutton_label_behaviors(behaviori),'String',sprintf('Label %s',handles.guidata.data.labelnames{behaviori}));

  set(handles.menu_file,'enable','on');
  set(handles.menu_edit,'enable','on');
  set(handles.menu_go,'enable','on');
  set(handles.menu_classifier,'enable','on');
  set(handles.pushbutton_train,'Enable','on');


end

guidata(hObject,handles);

function handles = SetLabelPlot(handles,t0,t1,behaviori,important)

% if behaviori == 0,
%   return;
% end

% if t == handles.lastframe_labeled,
%   warning('This should never happen');
%   keyboard;
% end
% 
% if isempty(handles.lastframe_labeled),
%   t0 = t;
%   t1 = t;
%   t2 = min(t+1,handles.guidata.t1_curr);
% else
%   if t < handles.lastframe_labeled,
%     t0 = t;
%     t1 = handles.lastframe_labeled-1;
%     t2 = handles.lastframe_labeled;
%   elseif t > handles.lastframe_labeled,
%     t0 = handles.lastframe_labeled+1;
%     t1 = t;
%     t2 = min(t+1,handles.guidata.t1_curr);
%   end
% end

% WARNING: this function directly accesses handles.guidata.data.labelidx, trx make sure
% that we've preloaded the right experiment and flies. 
% REMOVED!
% if handles.guidata.expi ~= handles.guidata.data.expi || ~all(handles.guidata.flies == handles.guidata.data.flies),
%   handles.guidata.data.Preload(handles.guidata.expi,handles.guidata.flies);
% end

if t1 < t0,
  tmp = t1;
  t1 = t0;
  t0 = tmp;
end
handles.guidata.labels_plot.x(:,t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off,:,:) = nan;
handles.guidata.labels_plot.y(:,t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off,:,:) = nan;
% handles.guidata.data.labelidx(t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off) = 0;

for channel = 1:3,
  handles.guidata.labels_plot.im(1,t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off,channel) = handles.guidata.labelunknowncolor(channel);
end
handles.guidata.data.SetLabel(handles.guidata.expi,handles.guidata.flies,t0:t1,behaviori,important);
if behaviori > 0,
  % handles.guidata.data.labelidx(t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off) = behaviori;
  for channel = 1:3,
    handles.guidata.labels_plot.im(1,t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off,channel) = handles.guidata.labelcolors(behaviori,channel);
  end
  for l = 1:numel(handles.guidata.flies),
    %off = handles.guidata.data.trx(handles.guidata.flies(l)).off;
    %j0 = t0+off;
    %j2 = t2+off;
    k0 = t0+handles.guidata.labels_plot_off;
    k2 = t1+handles.guidata.labels_plot_off+1;
    xplot = handles.guidata.data.GetTrxValues('X1',handles.guidata.expi,handles.guidata.flies(l),min(t0:t1+1,handles.guidata.t1_curr));
    yplot = handles.guidata.data.GetTrxValues('Y1',handles.guidata.expi,handles.guidata.flies(l),min(t0:t1+1,handles.guidata.t1_curr));
    handles.guidata.labels_plot.x(:,k0:k2-1,behaviori,l) = [xplot(1:end-1);xplot(2:end)];
    handles.guidata.labels_plot.y(:,k0:k2-1,behaviori,l) = [yplot(1:end-1);yplot(2:end)];      

%     handles.guidata.labels_plot.x(k0:k2,behaviori,l) = ...
%       handles.guidata.data.trx(handles.guidata.flies(l)).x(j0:j2);
%     handles.guidata.labels_plot.y(k0:k2,behaviori,l) = ...
%       handles.guidata.data.trx(handles.guidata.flies(l)).y(j0:j2);
  end
end

% isstart
if t0 == handles.guidata.t0_curr,
  handles.guidata.labels_plot.isstart(t0+handles.guidata.labels_plot_off) = behaviori ~= 0;
end
t00 = max(handles.guidata.t0_curr+1,t0);
off0 = t00+handles.guidata.labels_plot_off;
off1 = t1+handles.guidata.labels_plot_off;
% handles.guidata.labels_plot.isstart(off0:off1) = ...
%   handles.guidata.data.labelidx(off0:off1)~=0 & ...
%   handles.guidata.data.labelidx(off0-1:off1-1)~=handles.guidata.data.labelidx(off0:off1);
handles.guidata.labels_plot.isstart(off0:off1) = ...
  handles.guidata.data.IsLabelStart(handles.guidata.expi,handles.guidata.flies,t00:t1);

handles = UpdateErrors(handles);

handles = SetNeedSave(handles);

%handles.lastframe_labeled = t;

guidata(handles.figure_JLabel,handles);


function handles = SetLabelsPlot(handles,t0,t1,behavioris)


if t1 < t0,
  tmp = t1;
  t1 = t0;
  t0 = tmp;
end

handles.guidata.labels_plot.x(:,t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off,:,:) = nan;
handles.guidata.labels_plot.y(:,t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off,:,:) = nan;

for channel = 1:3,
  handles.guidata.labels_plot.im(1,t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off,channel) = handles.guidata.labelunknowncolor(channel);
end
handles.guidata.data.SetLabel(handles.guidata.expi,handles.guidata.flies,t0:t1,behavioris,0);

for behaviori = 1:handles.guidata.data.nbehaviors,

  bidx = find(behaviori == behavioris);
  if isempty(bidx),
    continue;
  end
  for channel = 1:3,
    handles.guidata.labels_plot.im(1,t0-1+bidx+handles.guidata.labels_plot_off,channel) = handles.guidata.labelcolors(behaviori,channel);
  end
  for l = 1:numel(handles.guidata.flies),
    ks = t0-1+handles.guidata.labels_plot_off+bidx;
    xplot0 = handles.guidata.data.GetTrxValues('X1',handles.guidata.expi,handles.guidata.flies(l),t0-1+bidx);
    xplot1 = handles.guidata.data.GetTrxValues('X1',handles.guidata.expi,handles.guidata.flies(l),min(t0+bidx,handles.guidata.t1_curr));
    handles.guidata.labels_plot.x(:,ks,behaviori,l) = [xplot0;xplot1];
    yplot0 = handles.guidata.data.GetTrxValues('Y1',handles.guidata.expi,handles.guidata.flies(l),t0-1+bidx);
    yplot1 = handles.guidata.data.GetTrxValues('Y1',handles.guidata.expi,handles.guidata.flies(l),min(t0+bidx,handles.guidata.t1_curr));
    handles.guidata.labels_plot.y(:,ks,behaviori,l) = [yplot0;yplot1];
  end
  
end

% isstart
if t0 == handles.guidata.t0_curr,
  handles.guidata.labels_plot.isstart(t0+handles.guidata.labels_plot_off) = behavioris(1) ~= 0;
end
t00 = max(handles.guidata.t0_curr+1,t0);
off0 = t00+handles.guidata.labels_plot_off;
off1 = t1+handles.guidata.labels_plot_off;
% handles.guidata.labels_plot.isstart(off0:off1) = ...
%   handles.guidata.data.labelidx(off0:off1)~=0 & ...
%   handles.guidata.data.labelidx(off0-1:off1-1)~=handles.guidata.data.labelidx(off0:off1);
handles.guidata.labels_plot.isstart(off0:off1) = ...
  handles.guidata.data.IsLabelStart(handles.guidata.expi,handles.guidata.flies,t00:t1);

handles = UpdateErrors(handles);

handles = SetNeedSave(handles);

%handles.lastframe_labeled = t;

guidata(handles.figure_JLabel,handles);


function handles = SetPredictedPlot(handles,t0,t1,behavioris)

if nargin < 2,
  [prediction,t0,t1] = handles.guidata.data.GetPredictedIdx(handles.guidata.expi,handles.guidata.flies);
elseif nargin < 4,
  prediction = handles.guidata.data.GetPredictedIdx(handles.guidata.expi,handles.guidata.flies,t0,t1);
end
behavioris = prediction.predictedidx;
scores = handles.guidata.data.NormalizeScores(prediction.scoresidx);
handles.guidata.labels_plot.predx(:,t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off,:,:) = nan;
handles.guidata.labels_plot.predy(:,t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off,:,:) = nan;

for behaviori = 1:handles.guidata.data.nbehaviors,

  bidx = find( (behaviori == behavioris) & ...
      (abs(scores)>handles.guidata.data.GetConfidenceThreshold(behaviori)));
  if isempty(bidx),
    continue;
  end
  for l = 1:numel(handles.guidata.flies),
    ks = t0-1+handles.guidata.labels_plot_off+bidx;
    xplot0 = handles.guidata.data.GetTrxValues('X1',handles.guidata.expi,handles.guidata.flies(l),t0-1+bidx);
    xplot1 = handles.guidata.data.GetTrxValues('X1',handles.guidata.expi,handles.guidata.flies(l),min(t0+bidx,handles.guidata.t1_curr));
    handles.guidata.labels_plot.predx(:,ks,behaviori,l) = [xplot0;xplot1];
    yplot0 = handles.guidata.data.GetTrxValues('Y1',handles.guidata.expi,handles.guidata.flies(l),t0-1+bidx);
    yplot1 = handles.guidata.data.GetTrxValues('Y1',handles.guidata.expi,handles.guidata.flies(l),min(t0+bidx,handles.guidata.t1_curr));
    handles.guidata.labels_plot.predy(:,ks,behaviori,l) = [yplot0;yplot1];
  end
  
end

guidata(handles.figure_JLabel,handles);

% --- Executes on button press in togglebutton_label_unknown.
function togglebutton_label_unknown_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_label_unknown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton_label_unknown
if get(hObject,'Value'),
  % toggle on
  handles.guidata.label_state = -1; 
  handles.guidata.label_imp = [];
  handles.label_t0 = handles.guidata.ts(1);

  % set everything else to off
  for j = 1:2*handles.guidata.data.nbehaviors,
    if isnan(handles.guidata.togglebutton_label_behaviors(j)), continue; end
    set(handles.guidata.togglebutton_label_behaviors(j),'Value',0,'Enable','off');
  end

  set(handles.guidata.htimeline_label_curr,'XData',handles.label_t0 + [-.5,-.5,.5,.5,-.5],...
    'FaceColor',handles.guidata.labelunknowncolor);
  
  UpdatePlots(handles,...
    'refreshim',false,'refreshflies',true,'refreshtrx',false,'refreshlabels',true,...
    'refresh_timeline_manual',true,...
    'refresh_timeline_auto',false,...
    'refresh_timeline_suggest',false,...
    'refresh_timeline_error',true,...
    'refresh_timeline_xlim',false,...
    'refresh_timeline_hcurr',false,...
    'refresh_timeline_props',false,...
    'refresh_timeline_selection',false,...
    'refresh_curr_prop',false);

  set(handles.menu_file,'enable','off');
  set(handles.menu_edit,'enable','off');
  set(handles.menu_go,'enable','off');
  set(handles.menu_classifier,'enable','off');
  set(handles.pushbutton_train,'Enable','off');
  

  
%   % set everything else to off
%   for j = 1:handles.guidata.data.nbehaviors,
%     set(handles.guidata.togglebutton_label_behaviors(j),'Value',0,'String',sprintf('Start %s',handles.guidata.data.labelnames{j}));
%   end
%   % set the current frame to be labeled
%   %handles.lastframe_labeled = [];
%   handles = SetLabelPlot(handles,min(handles.guidata.t1_curr,max(handles.guidata.t0_curr,handles.guidata.ts(1))),0);
%   UpdatePlots(handles,'refreshim',false,'refreshtrx',false,'refreshflies',false);
%   set(handles.togglebutton_label_unknown,'String','*Label Unknown*');

else
  
  if handles.guidata.ts(1) <= handles.label_t0,
    t0 = handles.guidata.ts(1);
    t1 = handles.label_t0;
  else
    t0 = handles.label_t0;
    t1 = handles.guidata.ts(1);
  end
  t0 = min(handles.guidata.t1_curr,max(handles.guidata.t0_curr,t0));
  t1 = min(handles.guidata.t1_curr,max(handles.guidata.t0_curr,t1));
  handles = SetLabelPlot(handles,t0,t1,0,0);

  handles.guidata.label_state = 0;
  handles.guidata.label_imp = [];
  handles.label_t0 = [];
  set(handles.guidata.htimeline_label_curr,'XData',nan(1,5));
    
  %handles.guidata.data.StoreLabels();
  for j = 1:2*handles.guidata.data.nbehaviors,
    if isnan(handles.guidata.togglebutton_label_behaviors(j)), continue; end
    buttonStr = sprintf('%s',handles.guidata.data.labelnames{ceil(j/2)});
    if handles.guidata.data.IsAdvancedMode() && mod(j,2); 
      buttonStr = sprintf('Important %s',buttonStr); 
    end
    set(handles.guidata.togglebutton_label_behaviors(j),'Value',0,'String',buttonStr,'Enable','on');
  end
  set(handles.togglebutton_label_unknown,'Value',0,'String','Unknown','Enable','on');  
  UpdatePlots(handles,...
    'refreshim',false,'refreshflies',true,'refreshtrx',false,'refreshlabels',true,...
    'refresh_timeline_manual',true,...
    'refresh_timeline_auto',false,...
    'refresh_timeline_suggest',false,...
    'refresh_timeline_error',true,...
    'refresh_timeline_xlim',false,...
    'refresh_timeline_hcurr',false,...
    'refresh_timeline_props',false,...
    'refresh_timeline_selection',false,...
    'refresh_curr_prop',false);
  
%   handles.guidata.label_state = 0;
%   %handles.guidata.data.StoreLabels();
%   set(handles.togglebutton_label_unknown,'String','Start Unknown');
  set(handles.menu_file,'enable','on');
  set(handles.menu_edit,'enable','on');
  set(handles.menu_go,'enable','on');
  set(handles.menu_classifier,'enable','on');
  set(handles.pushbutton_train,'Enable','on');
   
end

guidata(hObject,handles);

function edit_framenumber_Callback(hObject, eventdata, handles)
% hObject    handle to edit_framenumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_framenumber as text
%        str2double(get(hObject,'String')) returns contents of edit_framenumber as a double
v = str2double(get(hObject,'String'));
i = GetPreviewPanelNumber(hObject);
if isnan(v) || isempty(v),
  set(hObject,'String',num2str(handles.guidata.ts(i)));
else
  v = round(v);
  if v >= handles.guidata.t0_curr && v <= handles.guidata.t1_curr
    handles = SetCurrentFrame(handles,i,v,hObject);
  else
    warndlg('Frame number should be within the range for the current fly');
    set(hObject,'String',num2str(handles.guidata.ts(i)));
  end
  guidata(hObject,handles);
end

% --- Executes during object creation, after setting all properties.
function edit_framenumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_framenumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function menu_view_timeline_options_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_timeline_options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

prompts = {'N. frames shown:'};
answers = {num2str(handles.guidata.timeline_nframes)};
res = inputdlg(prompts,'Timeline view options',numel(prompts),answers);
if isempty(res); return; end;
handles.guidata.timeline_nframes = str2double(res{1});

xlim = [handles.guidata.ts(1)-(handles.guidata.timeline_nframes-1)/2,...
  handles.guidata.ts(1)+(handles.guidata.timeline_nframes-1)/2];
for i = 1:numel(handles.guidata.axes_timelines),
  set(handles.guidata.axes_timelines(i),'XLim',xlim);
  zoom(handles.guidata.axes_timelines(i),'reset');
end
guidata(hObject,handles);


% --- Executes on mouse press over axes background.
function axes_preview_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes_preview (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% WARNING: this function directly accesses handles.guidata.data.trx make sure
% that we've preloaded the right experiment and flies. 
% REMOVED!

if ~handles.guidata.enabled,
  return;
end

% double-click does nothing
if strcmpi(get(handles.figure_JLabel,'SelectionType'),'open'),
  return;
end

if handles.guidata.expi ~= handles.guidata.data.expi,
  handles.guidata.data.Preload(handles.guidata.expi,handles.guidata.flies);
end

% which preview panel is this
i = GetPreviewPanelNumber(hObject);
nprev = handles.guidata.traj_nprev;
npost = handles.guidata.traj_npost;
mind = inf;
pt = get(handles.guidata.axes_previews(i),'CurrentPoint');
xclick = pt(1,1);
yclick = pt(1,2);
dx = diff(get(handles.guidata.axes_previews(i),'XLim'));
dy = diff(get(handles.guidata.axes_previews(i),'YLim'));
for j = 1:numel(handles.guidata.flies),
  fly = handles.guidata.flies(j);
  T0 = handles.guidata.data.firstframes_per_exp{handles.guidata.expi}(fly);
  T1 = handles.guidata.data.endframes_per_exp{handles.guidata.expi}(fly);
  t0 = min(T1,max(T0,handles.guidata.ts(i)-nprev));
  t1 = min(T1,max(T0,handles.guidata.ts(i)+npost));
  %off = handles.guidata.data.trx(fly).off;
%   [mindcurr,k] = min( ((handles.guidata.data.trx(fly).x(t0+off:t1+off)-xclick)/dx).^2 + ...
%     ((handles.guidata.data.trx(fly).y(t0+off:t1+off)-yclick)/dy).^2 );
  [mindcurr,k] = min( ((handles.guidata.data.GetTrxValues('X1',handles.guidata.expi,fly,t0:t1)-xclick)/dx).^2 + ...
    ((handles.guidata.data.GetTrxValues('Y1',handles.guidata.expi,fly,t0:t1)-yclick)/dy).^2 );
  if mindcurr < mind,
    mind = mindcurr;
    mint = k+t0-1;
  end
end
if mind <= handles.guidata.max_click_dist_preview
  handles = SetCurrentFrame(handles,i,mint,hObject);
end
guidata(hObject,handles);


function fly_ButtonDownFcn(hObject, eventdata, handles, flyi, i)

fly = handles.guidata.idx2fly(flyi);

% TODO: figure out how to do this when multiple flies define a behavior

if ~handles.guidata.enabled,
  return;
end

% check for double click
if ~strcmpi(get(handles.figure_JLabel,'SelectionType'),'open') || ...
    numel(handles.guidata.flies) == 1 && handles.guidata.flies == fly,
  % call the axes button down fcn
  axes_preview_ButtonDownFcn(handles.axes_preview(i), eventdata, handles);
  return;
end

% Dont switch flies when the label pen is down.
penDown = false;
if ~handles.guidata.data.IsAdvancedMode(),
  behaviorVals = get(handles.guidata.togglebutton_label_behaviors(1:2:end),'Value');
else
  behaviorVals = get(handles.guidata.togglebutton_label_behaviors,'Value');
end

for ndx = 1:length(behaviorVals)
  penDown = penDown | behaviorVals{ndx};
end
penDown = penDown | get(handles.togglebutton_label_unknown,'Value');
if penDown, return; end

% check if the user wants to switch to this fly
% TODO: this directly accesses handles.guidata.data.labels -- abstract this
[ism,j] = ismember(fly,handles.guidata.data.labels(handles.guidata.expi).flies,'rows');
if ism,
  nbouts = nnz(~strcmpi(handles.guidata.data.labels(handles.guidata.expi).names{j},'None'));
else
  nbouts = 0;
end

endframe = handles.guidata.data.endframes_per_exp{handles.guidata.expi}(fly);
firstframe = handles.guidata.data.firstframes_per_exp{handles.guidata.expi}(fly);
prompt = {sprintf('Switch to fly %d?',fly),...
  sprintf('Trajectory length = %d',endframe-firstframe+1),...
  sprintf('First frame = %d',firstframe),...
  sprintf('N. bouts labeled: %d',nbouts)};

if handles.guidata.data.hassex,
  if handles.guidata.data.hasperframesex,
    sexfrac = handles.guidata.data.GetSexFrac(handles.guidata.expi,fly);
    prompt{end+1} = sprintf('Sex: %d%%M, %d%%F',round(sexfrac.M*100),round(sexfrac.F*100));
  else
    t = max(handles.guidata.t0_curr,handles.guidata.ts(1));
    sex = handles.guidata.data.GetSex(handles.guidata.expi,fly,t);
    if iscell(sex),
      sex = sex{1};
    end
    prompt{i} = sprintf('Sex: %s',sex);
  end
end

res = questdlg(prompt,...
  'Change flies?','Yes','No','Yes');

if strcmpi(res,'No'),
  return;
end

SetCurrentFlies(handles,fly);


% --- Executes on mouse press over axes background.
function axes_timeline_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes_timeline_manual (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~handles.guidata.enabled,
  return;
end

pt = get(hObject,'CurrentPoint');
t = min(max(handles.guidata.t0_curr,round(pt(1,1))),handles.guidata.t1_curr);%nframes);
% TODO: which axes?
SetCurrentFrame(handles,1,t,hObject);


% --- Executes on button press in pushbutton_train.
function pushbutton_train_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_train (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% store the current labels to windowdata_labeled
handles.guidata.data.StoreLabels();
handles.guidata.data.Train(handles.guidata.doFastUpdates);
handles = SetPredictedPlot(handles);
% predict for current window
handles = UpdatePrediction(handles);
handles = SetNeedSave(handles);
guidata(hObject,handles);

function handles = UpdatePrediction(handles)

% update prediction for currently shown timeline
% TODO: make this work for multiple axes
t0 = max(handles.guidata.t0_curr,floor(handles.guidata.ts(1)-handles.guidata.timeline_nframes/2));
t1 = min(handles.guidata.t1_curr,ceil(handles.guidata.ts(1)+7*handles.guidata.timeline_nframes/2));
handles.guidata.data.Predict(handles.guidata.expi,handles.guidata.flies,t0,t1);
handles = SetPredictedPlot(handles);

handles = UpdateTimelineIms(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);

function handles = UpdateErrors(handles)

% update prediction for currently shown timeline
% TODO: make this work for multiple axes
handles.guidata.data.UpdateErrorIdx();
handles = UpdateTimelineIms(handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',...
  false,'refreshtrx',false,'refreshlabels',false,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);

% --- Executes on button press in pushbutton_predict.
function pushbutton_predict_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_predict (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = UpdatePrediction(handles);
guidata(hObject,handles);

% --- Executes on key press with focus on figure_JLabel or any of its controls.
function figure_JLabel_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure_JLabel (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

%disp(eventdata.Character);
%disp(eventdata.Modifier);

function SetStatusCallback(s,h)

handles = guidata(h);
SetStatus(handles,s);

function ClearStatusCallback(h)

handles = guidata(h);
ClearStatus(handles);

function SetStatus(handles,s,isbusy)

if nargin < 3 || isbusy,
  color = handles.guidata.busystatuscolor;
else
  color = handles.guidata.idlestatuscolor;
end
set(handles.text_status,'ForegroundColor',color,'String',s);

set(handles.figure_JLabel,'Pointer','watch');

if strcmpi(get(handles.figure_JLabel,'Visible'),'off'),
  msgbox(s,'JAABA Status','modal');
end

function ClearStatus(handles)

set(handles.text_status,'ForegroundColor',handles.guidata.idlestatuscolor,'String',handles.guidata.status_bar_text);
set(handles.figure_JLabel,'Pointer','arrow');
h = findall(0,'Type','figure','Name','JAABA Status');
if ~isempty(h), delete(h(ishandle(h))); end


% --------------------------------------------------------------------
function menu_file_load_top_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_load_top (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%{
% --------------------------------------------------------------------
% function menu_go_switch_experiment_Callback(hObject, eventdata, handles)
% % hObject    handle to menu_go_switch_experiment (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% s = cell(1,handles.guidata.data.nexps);
% for i = 1:handles.guidata.data.nexps,
%   expStats = handles.guidata.data.GetExpStats(i);
%   if i == handles.guidata.expi,
%     s{i} = sprintf('%s, N flies: %d, OPEN NOW',...
%       expStats.name,expStats.nflies);
%   else
%     s{i} = sprintf('%s, N flies: %d',expStats.name,expStats.nflies);
%     if handles.guidata.data.hassex,
%       nmales = sum([handles.guidata.data.frac_sex_per_exp{i}.M]);
%       nfemales = sum([handles.guidata.data.frac_sex_per_exp{i}.F]);
%       if handles.guidata.data.hasperframesex,
%         s{i} = [s{i},sprintf('(%.1f M, %.1f F)',nmales,nfemales)];
%       else
%         s{i} = [s{i},sprintf('(%d M, %d F)',nmales,nfemales)];
%       end
%     end
%     s{i} = [s{i},sprintf(', N flies labeled: %d, N bouts labeled: %d, last labeled: %s',...
%       expStats.nlabeledflies,...
%       expStats.nlabeledbouts,...
%       expStats.labeldatestr)];
%     if ~isempty(expStats.nscoreframes)
%       s{i} = [s{i},sprintf(', Frames Predicted as %s:%d, Total Frames Predicted:%d, Classifier used to predict:%s',...
%         handles.guidata.data.labelnames{1},...
%         expStats.nscorepos,...
%         expStats.nscoreframes,...
%         expStats.classifierfilename)];
%     end
%     
%   end
% end
% [expi,ok] = listdlg('ListString',s,'SelectionMode','single',...
%   'InitialValue',handles.guidata.expi,'Name','Switch experiment',...
%   'PromptString','Select experiment:',...
%   'ListSize',[640,300]);
% if ~ok || expi == handles.guidata.expi,
%   return;
% end
% [handles,success] = SetCurrentMovie(handles,expi);
% if ~success,
%   return;
% end
% guidata(hObject,handles);

% --------------------------------------------------------------------
% function menu_go_switch_target_Callback(hObject, eventdata, handles)
% % hObject    handle to menu_go_switch_target (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % TODO: generalize this to multiple flies labeled
% 
% nflies = handles.guidata.data.nflies_per_exp(handles.guidata.expi);
% s = cell(1,nflies);
% for fly = 1:nflies,
%   if fly == handles.guidata.flies(1),
%     s{fly} = sprintf('Target %3d, CURRENTLY SELECTED',fly);
%   else
%     flyStats = handles.guidata.data.GetFlyStats(handles.guidata.expi,fly);
%     s{fly} = sprintf('Target %3d, Trajectory length %5d, First frame %5d, N bouts labeled %2d',...
%       fly,flyStats.trajLength,flyStats.firstframe,flyStats.nbouts);
%     if flyStats.hassex,
%       if ~isempty(flyStats.sexfrac),
%         s{fly} = [s{fly},sprintf(', Sex: %3d%%M, %3d%%F',...
%           round(flyStats.sexfrac.M*100),round(flyStats.sexfrac.F*100))];
%       else
%         s{fly} = [s{fly},sprintf(', Sex: %s',flyStats.sex{1})];
%       end
%     end
%     if ~isempty(flyStats.nscoreframes)
%       s{fly} = [s{fly},sprintf(', Frames Predicted as %s:%d, Total Frames Predicted:%d',...
%         handles.guidata.data.labelnames{1},flyStats.nscorepos,flyStats.nscoreframes)];
%     end
%   end
% end
% 
% 
% [fly,ok] = listdlg('ListString',s,'SelectionMode','single',...
%   'InitialValue',handles.guidata.flies(1),'Name','Switch target',...
%   'PromptString','Select experiment:',...
%   'ListSize',[640,300]);
% if ~ok || fly == handles.guidata.flies(1),
%   return;
% end
% handles = SetCurrentFlies(handles,fly);
% guidata(hObject,handles);
%}

% --------------------------------------------------------------------
function menu_view_zoom_in_on_fly_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_zoom_in_on_fly (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.guidata.preview_zoom_mode = 'center_on_fly';
set(setdiff(handles.guidata.menu_view_zoom_options,hObject),'Checked','off');
set(hObject,'Checked','on');
ZoomInOnFlies(handles);
guidata(hObject,handles);

function ZoomInOnFlies(handles,is)

% WARNING: this function accesses handles.guidata.data.trx directly -- this requires
% the correct experiment to be loaded
% REMOVED!

if nargin < 2,
  is = 1:numel(handles.guidata.axes_previews);
end

xs = nan(1,numel(handles.guidata.flies));
ys = nan(1,numel(handles.guidata.flies));
for i = is,
  firstframes = handles.guidata.data.firstframes_per_exp{handles.guidata.expi}(handles.guidata.flies);
  endframes = handles.guidata.data.endframes_per_exp{handles.guidata.expi}(handles.guidata.flies);
  %inds = handles.guidata.ts(i)-firstframes+1;
  for j = 1:numel(handles.guidata.flies),
    if handles.guidata.ts(i) < firstframes(j) || handles.guidata.ts(i) > endframes(j),
      continue;
    end
    xs(j) = handles.guidata.data.GetTrxValues('X1',handles.guidata.expi,handles.guidata.flies(j),handles.guidata.ts(i));
    ys(j) = handles.guidata.data.GetTrxValues('Y1',handles.guidata.expi,handles.guidata.flies(j),handles.guidata.ts(i));
    %xs(j) = handles.guidata.data.trx(handles.guidata.flies(j)).x(inds(j));
    %ys(j) = handles.guidata.data.trx(handles.guidata.flies(j)).y(inds(j));
  end
  if ~all(isnan(xs)) && ~all(isnan(ys)),
    %xlim = [max([.5,xs-handles.guidata.zoom_fly_radius(1)]),min([handles.guidata.movie_width+.5,xs+handles.guidata.zoom_fly_radius(1)])];
    %ylim = [max([.5,ys-handles.guidata.zoom_fly_radius(2)]),min([handles.guidata.movie_height+.5,ys+handles.guidata.zoom_fly_radius(2)])];
    x0 = min(xs) - handles.guidata.zoom_fly_radius(1);
    x1 = max(xs) + handles.guidata.zoom_fly_radius(1);
    if x1 - x0 + 1 >= handles.guidata.movie_width,
      xlim = [.5,handles.guidata.movie_width+.5];
    elseif x0 < .5,
      dx = .5 - x0;
      xlim = [.5,x1 + dx];
    elseif x1 > handles.guidata.movie_width+.5,
      dx = x1 - (handles.guidata.movie_width+.5);
      xlim = [x0-dx,handles.guidata.movie_width+.5];
    else
      xlim = [x0,x1];
    end
    y0 = min(ys) - handles.guidata.zoom_fly_radius(2);
    y1 = max(ys) + handles.guidata.zoom_fly_radius(2);
    if y1 - y0 + 1 >= handles.guidata.movie_height,
      ylim = [.5,handles.guidata.movie_height+.5];
    elseif y0 < .5,
      dy = .5 - y0;
      ylim = [.5,y1 + dy];
    elseif y1 > handles.guidata.movie_height+.5,
      dy = y1 - (handles.guidata.movie_height+.5);
      ylim = [y0-dy,handles.guidata.movie_height+.5];
    else
      ylim = [y0,y1];
    end    
    set(handles.guidata.axes_previews(i),'XLim',xlim,'YLim',ylim);
  end
end

function KeepFliesInView(handles,is)

% WARNING: this function accesses handles.guidata.data.trx directly -- this requires
% the correct experiment to be loaded
% REMOVED!

if nargin < 2,
  is = 1:numel(handles.guidata.axes_previews);
end

xs = nan(1,numel(handles.guidata.flies));
ys = nan(1,numel(handles.guidata.flies));
for i = is,
  firstframes = handles.guidata.data.firstframes_per_exp{handles.guidata.expi}(handles.guidata.flies);
  endframes = handles.guidata.data.endframes_per_exp{handles.guidata.expi}(handles.guidata.flies);
  %inds = handles.guidata.ts(i)-firstframes+1;
  for j = 1:numel(handles.guidata.flies),
    if handles.guidata.ts(i) < firstframes(j) || handles.guidata.ts(i) > endframes(j),
      continue;
    end
    xs(j) = handles.guidata.data.GetTrxValues('X1',handles.guidata.expi,handles.guidata.flies(j),handles.guidata.ts(i));
    ys(j) = handles.guidata.data.GetTrxValues('Y1',handles.guidata.expi,handles.guidata.flies(j),handles.guidata.ts(i));
    %xs(j) = handles.guidata.data.trx(handles.guidata.flies(j)).x(inds(j));
    %ys(j) = handles.guidata.data.trx(handles.guidata.flies(j)).y(inds(j));
  end
  xlim = get(handles.guidata.axes_previews(i),'XLim');
  % a little border at the edge of the image
  border = .1;
  dx = diff(xlim);
  
  if xlim(1) > .5,
    xlim(1) = xlim(1) + dx*border;
  end
  if xlim(2) < handles.guidata.movie_width+.5,
    xlim(2) = xlim(2) - dx*border;
  end
  ylim = get(handles.guidata.axes_previews(i),'YLim');
  dy = diff(ylim);
  if ylim(1) > .5,
    ylim(1) = ylim(1) + dy*border;
  end
  if ylim(2) < handles.guidata.movie_height+.5,
    ylim(2) = ylim(2) - dy*border;
  end
  if min(xs)-handles.guidata.meana*2 < xlim(1) || min(ys)-handles.guidata.meana*2 < ylim(1) || ...
      max(xs)+handles.guidata.meana*2 > xlim(2) || max(ys)+handles.guidata.meana*2 > ylim(2),
    % center on flies
    newxlim = [max([.5,xs-handles.guidata.zoom_fly_radius(1)]),min([handles.guidata.movie_width+.5,xs+handles.guidata.zoom_fly_radius(1)])];
    newylim = [max([.5,ys-handles.guidata.zoom_fly_radius(2)]),min([handles.guidata.movie_height+.5,ys+handles.guidata.zoom_fly_radius(2)])];
    set(handles.guidata.axes_previews(i),'XLim',newxlim,'YLim',newylim);    
  end
end

function ShowWholeVideo(handles,is)

if nargin < 2,
  is = 1:numel(handles.guidata.axes_previews);
end

for i = is,
  newxlim = [.5,handles.guidata.movie_width+.5];
  newylim = [.5,handles.guidata.movie_height+.5];
  set(handles.guidata.axes_previews(i),'XLim',newxlim,'YLim',newylim);  
end

% --------------------------------------------------------------------
function menu_file_save_labels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_save_labels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.guidata.data.SaveLabels();
handles.guidata.data.SaveGTLabels();

% --------------------------------------------------------------------
function menu_edit_clear_all_labels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_clear_all_labels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

s = {};
s{end+1} = 'Experiments with labels: ';
for i = 1:numel(handles.guidata.data.labelstats),
  if handles.guidata.data.labelstats(i).nbouts_labeled > 0,
    s{end+1} = sprintf('%s: %d bouts',handles.guidata.data.expnames{i},handles.guidata.data.labelstats(i).nbouts_labeled); %#ok<AGROW>
  end
end

res = questdlg(s,'Really delete all labels?','Yes','No','Cancel','Cancel');
if strcmpi(res,'Yes'),
  handles.guidata.data.ClearLabels();
  handles = UpdateTimelineIms(handles);
  UpdatePlots(handles);
end

function RecursiveSetKeyPressFcn(hfig)

hchil = findall(hfig,'-property','KeyPressFcn');
goodidx = true(1,numel(hchil));
for i = 1:numel(hchil),
  if strcmpi(get(hchil(i),'Type'),'uicontrol') && strcmpi(get(hchil(i),'Style'),'edit'),
    goodidx(i) = false;
  end
end
set(hchil(goodidx),'KeyPressFcn',get(hfig,'KeyPressFcn'));

% --- Executes on key release with focus on figure_JLabel and none of its controls.
function figure_JLabel_KeyReleaseFcn(hObject, eventdata, handles)
% hObject    handle to figure_JLabel (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was released, in lower case
%	Character: character interpretation of the key(s) that was released
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) released
% handles    structure with handles and user data (see GUIDATA)
switch eventdata.Key,
  case 'space',
    pushbutton_playstop_Callback(handles.pushbutton_playstop,[],handles);
end

% --- Executes on key press with focus on figure_JLabel and none of its controls.
function figure_JLabel_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure_JLabel (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

if ~handles.guidata.enabled,
  return;
end

if strcmpi(eventdata.Modifier,'control')
  switch eventdata.Key,
    case 't',
      if ~handles.guidata.data.IsGTMode(),
        pushbutton_train_Callback(hObject,eventdata,handles);
      end
      
    case 'p',
        pushbutton_predict_Callback(hObject,eventdata,handles);
    case 'n',
      menu_go_navigation_preferences_Callback(hObject,eventdata,handles);
    case 'j',
      menu_go_switch_target_Callback(hObject,eventdata,handles);
    case 'k'
      menu_view_plottracks_Callback(handles.menu_view_plottracks,eventdata,handles);
  end
end

switch eventdata.Key,
  
  case 'leftarrow',
    if ~isempty(eventdata.Modifier) && any(strcmpi(eventdata.Modifier,{'control','command'})),
      menu_go_previous_bout_end_Callback(hObject,eventdata,handles);
    elseif strcmpi(eventdata.Modifier,'shift'),
      menu_go_previous_automatic_bout_end_Callback(hObject,eventdata,handles);
    else
      menu_go_previous_frame_Callback(hObject, eventdata, handles);
    end
     
  case 'rightarrow',
    if ~isempty(eventdata.Modifier) && any(strcmpi(eventdata.Modifier,{'control','command'})),
      menu_go_next_bout_start_Callback(hObject,eventdata,handles);
    elseif strcmpi(eventdata.Modifier,'shift'),
      menu_go_next_automatic_bout_start_Callback(hObject,eventdata,handles);
    else
      menu_go_next_frame_Callback(hObject, eventdata, handles);
    end
  
  case 'uparrow',
    menu_go_back_X_frames_Callback(hObject, eventdata, handles);
    
  case 'downarrow',
    menu_go_forward_X_frames_Callback(hObject, eventdata, handles);

    
  case handles.guidata.label_shortcuts,
    buttonNum = find(strcmp(eventdata.Key,handles.guidata.label_shortcuts),1);
    if buttonNum > 2*handles.guidata.data.nbehaviors,
      if handles.guidata.label_state > 0,
        buttonNum = 2*handles.guidata.label_state - handles.guidata.label_imp;
        set(handles.guidata.togglebutton_label_behaviors(buttonNum),'Value',false);
        togglebutton_label_behavior1_Callback(handles.guidata.togglebutton_label_behaviors(buttonNum), eventdata, handles);
        handles = guidata(hObject);
      end
      set(handles.togglebutton_label_unknown,'Value',get(handles.togglebutton_label_unknown,'Value')==0);
      togglebutton_label_unknown_Callback(handles.togglebutton_label_unknown, eventdata, handles);
      return;
    else
      if ~handles.guidata.data.IsAdvancedMode() && ~mod(buttonNum,2); return; end 
      % Don't do anything when unimportant label keys are pressed in the Normal mode
      if handles.guidata.label_state == -1,
        set(handles.togglebutton_label_unknown,'Value',false);
        togglebutton_label_unknown_Callback(handles.togglebutton_label_unknown, eventdata, handles);
        handles = guidata(hObject);
      elseif handles.guidata.label_state > 0 && (2*handles.guidata.label_state -handles.guidata.label_imp)~= buttonNum,
        prevButtonNum = 2*handles.guidata.label_state - handles.guidata.label_imp;
        set(handles.guidata.togglebutton_label_behaviors(prevButtonNum),'Value',false);
        togglebutton_label_behavior1_Callback(handles.guidata.togglebutton_label_behaviors(prevButtonNum), eventdata, handles);
        handles = guidata(hObject);
      end
      set(handles.guidata.togglebutton_label_behaviors(buttonNum),'Value',...
        get(handles.guidata.togglebutton_label_behaviors(buttonNum),'Value')==0);
      togglebutton_label_behavior1_Callback(handles.guidata.togglebutton_label_behaviors(buttonNum), eventdata, handles);
      return;
    end
  case {'esc','escape'},
    if get(handles.togglebutton_label_unknown,'Value') ~= 0,
      set(handles.togglebutton_label_unknown,'Value',0);
      togglebutton_label_unknown_Callback(handles.togglebutton_label_unknown, eventdata, handles);
    else
      for behaviori = 1:2*handles.guidata.data.nbehaviors,
        if isnan(handles.guidata.togglebutton_label_behaviors(behaviori)), continue; end
        if get(handles.guidata.togglebutton_label_behaviors(behaviori),'Value') ~= 0,
          set(handles.guidata.togglebutton_label_behaviors(behaviori),'Value',0);
          togglebutton_label_behavior1_Callback(handles.guidata.togglebutton_label_behaviors(behaviori), eventdata, handles);
        end
      end
    end
    
end


% --------------------------------------------------------------------
function menu_go_next_frame_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_next_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% TODO: make this work with multiple preview axes
axesi = 1;
t = min(max(1,handles.guidata.ts(axesi)+1),handles.guidata.t1_curr);%handles.guidata.nframes);
% set current frame
SetCurrentFrame(handles,axesi,t,hObject);

% --------------------------------------------------------------------
function menu_go_previous_frame_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_previous_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% TODO: make this work with multiple preview axes
axesi = 1;
t = min(max(handles.guidata.t0_curr,handles.guidata.ts(axesi)-1),handles.guidata.t1_curr);
% set current frame
SetCurrentFrame(handles,axesi,t,hObject);


% --------------------------------------------------------------------
function menu_go_forward_X_frames_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_forward_X_frames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% TODO: make this work with multiple preview axes
axesi = 1;
% TODO: hardcoded in 10 as up/down arrow step
t = min(max(handles.guidata.t0_curr,handles.guidata.ts(axesi)+handles.guidata.nframes_jump_go),handles.guidata.t1_curr);%nframes);
% set current frame
SetCurrentFrame(handles,axesi,t,hObject);


% --------------------------------------------------------------------
function menu_go_back_X_frames_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_back_X_frames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% TODO: make this work with multiple preview axes
axesi = 1;
% TODO: hardcoded in 10 as up/down arrow step
t = min(max(handles.guidata.t0_curr,handles.guidata.ts(axesi)-handles.guidata.nframes_jump_go),handles.guidata.t1_curr);%nframes);
% set current frame
SetCurrentFrame(handles,axesi,t,hObject);


% --------------------------------------------------------------------
function menu_go_next_bout_start_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_next_bout_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% TODO: make this work with multiple preview axes
axesi = 1;

t = handles.guidata.NJObj.Manual_bout_start(handles.guidata.data,handles.guidata.expi,handles.guidata.flies,...
  handles.guidata.ts(axesi),handles.guidata.t0_curr,handles.guidata.t1_curr);
if isempty(t); return; end

SetCurrentFrame(handles,axesi,t,hObject);

% --------------------------------------------------------------------
function menu_go_previous_bout_end_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_previous_bout_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% TODO: make this work with multiple preview axes
axesi = 1;

t = handles.guidata.NJObj.Manual_bout_end(handles.guidata.data,handles.guidata.expi,handles.guidata.flies,...
  handles.guidata.ts(axesi),handles.guidata.t0_curr,handles.guidata.t1_curr);
if isempty(t); return; end

SetCurrentFrame(handles,axesi,t,hObject);


% --------------------------------------------------------------------
function menu_go_navigation_preferences_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_navigation_preferences (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'figure_NavigationPreferences') && ishandle(handles.figure_NavigationPreferences),
  figure(handles.figure_NavigationPreferences);
else
  handles.figure_NavigationPreferences = NavigationPreferences(handles.figure_JLabel,handles.guidata.NJObj);
  handles.guidata.open_peripherals(end+1) = handles.figure_NavigationPreferences;
  guidata(hObject,handles);
end


% --------------------------------------------------------------------
function menu_edit_label_shortcuts_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_label_shortcuts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

prompts  = {};
allShortcuts = handles.guidata.label_shortcuts;
curShortcuts = {};
tprompts = {};
for j = 1:2*handles.guidata.data.nbehaviors
    
  labelStr = handles.guidata.data.labelnames{ceil(j/2)};
  if mod(j,2), 
    labelStr = ['Important ' labelStr];
  end
  tprompts{end+1} = labelStr;
  
  if ~handles.guidata.data.IsAdvancedMode() && ~mod(j,2); continue; end
  % Don't show unimportant keys for Normal mode.
  labelStr = handles.guidata.data.labelnames{ceil(j/2)};
  if handles.guidata.data.IsAdvancedMode() && mod(j,2), 
    labelStr = ['Important ' labelStr];
  end
  prompts{end+1} = labelStr;
  curShortcuts{end+1} = allShortcuts{j};
end
prompts{end+1} = 'Unknown';
tprompts{end+1} = 'Unknown';
curShortcuts{end+1} = allShortcuts{end};
sh = inputdlg(prompts,'Label Shortcuts',1,curShortcuts);
if isempty(sh),
  return;
end

curshortcuts = allShortcuts;
if ~handles.guidata.data.IsAdvancedMode()
  curshortcuts(1:2:2*handles.guidata.data.nbehaviors)= sh(1:handles.guidata.data.nbehaviors);
  curshortcuts(2*handles.guidata.data.nbehaviors+1)= sh(handles.guidata.data.nbehaviors+1);
else
  curshortcuts = sh;
end
[uniquekeys,occ,ndx] = unique(curshortcuts);
nbeh = handles.guidata.data.nbehaviors;
if numel(uniquekeys)~= 2*nbeh+1
  overlap = [];
  for ndx = 1:2*nbeh+1
    nb = find(strcmp(curshortcuts{ndx},curshortcuts));
    if numel(nb) > 1,
      overlap = [overlap ', ' tprompts{ndx} ':' curshortcuts{ndx}];
    end
  end
  overlap = overlap(3:end);
  uiwait(warndlg(sprintf(...
      'Some short cut keys are assigned to multiple behaviors:%s',overlap))); 
  return;
end

if ~handles.guidata.data.IsAdvancedMode()
  handles.guidata.label_shortcuts(1:2:2*handles.guidata.data.nbehaviors)= sh(1:handles.guidata.data.nbehaviors);
  handles.guidata.label_shortcuts(2*handles.guidata.data.nbehaviors+1)= sh(handles.guidata.data.nbehaviors+1);
else
  handles.guidata.label_shortcuts = sh;
end
guidata(hObject,handles);


% --- Executes when figure_JLabel is resized.
function figure_JLabel_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure_JLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isfield(handles,'guidata') || ~isfield(handles.guidata.guipos,'leftborder_leftpanels'),
  return;
end

set(handles.figure_JLabel,'Units','pixels');
figpos = get(handles.figure_JLabel,'Position');

minh = 700;
minw = 500;
if figpos(3) < minw || figpos(4) < minh,
  figpos(3:4) = max(figpos(3:4),[minw,minh]);
  set(handles.figure_JLabel,'Position',figpos);
end

labelbuttons_pos = get(handles.panel_labelbuttons,'Position');
select_pos = get(handles.panel_select,'Position');
learn_pos = get(handles.panel_learn,'Position');
similar_pos = get(handles.panel_similar,'Position');
info_pos = get(handles.panel_selection_info,'Position');

width_leftpanels = figpos(3) - handles.guidata.guipos.leftborder_leftpanels - ...
  handles.guidata.guipos.leftborder_rightpanels - handles.guidata.guipos.width_rightpanels - ...
  handles.guidata.guipos.rightborder_rightpanels;
h = figpos(4) - handles.guidata.guipos.bottomborder_bottompanels - ...
  handles.guidata.guipos.topborder_toppanels - handles.guidata.guipos.bottomborder_previewpanels;
height_timelines = h*handles.guidata.guipos.frac_height_timelines;
height_previews = h - height_timelines;
timelines_pos = [handles.guidata.guipos.leftborder_leftpanels,handles.guidata.guipos.bottomborder_bottompanels,...
  width_leftpanels,height_timelines];
set(handles.panel_timelines,'Position',timelines_pos);
% TODO: deal with multiple preview panels
preview_pos = [handles.guidata.guipos.leftborder_leftpanels,...
  figpos(4) - handles.guidata.guipos.topborder_toppanels - height_previews,...
  width_leftpanels,height_previews];
set(handles.guidata.panel_previews(1),'Position',preview_pos);

label_pos = [figpos(3) - labelbuttons_pos(3) - handles.guidata.guipos.rightborder_rightpanels,...
  figpos(4) - labelbuttons_pos(4) - handles.guidata.guipos.topborder_toppanels,...
  labelbuttons_pos(3:4)];
set(handles.panel_labelbuttons,'Position',label_pos);

dy_label_select = labelbuttons_pos(2) - select_pos(2) - select_pos(4);
new_select_pos = [figpos(3) - select_pos(3) - handles.guidata.guipos.rightborder_rightpanels,...
  label_pos(2) - select_pos(4) - dy_label_select,...
  select_pos(3:4)];
set(handles.panel_select,'Position',new_select_pos);

%dy_label_select = labelbuttons_pos(2) - select_pos(2) - select_pos(4);
if ~handles.guidata.data.IsAdvancedMode() || handles.guidata.data.IsGTMode(),
  set(handles.panel_similar,'Visible','off');
  new_info_pos = [figpos(3) - info_pos(3) - handles.guidata.guipos.rightborder_rightpanels,...
    new_select_pos(2) - info_pos(4) - dy_label_select,...
    info_pos(3:4)];
  set(handles.panel_selection_info,'Position',new_info_pos);
else
  new_similar_pos = [figpos(3) - similar_pos(3) - handles.guidata.guipos.rightborder_rightpanels,...
    new_select_pos(2) - similar_pos(4) - dy_label_select,...
    similar_pos(3:4)];
  set(handles.panel_similar,'Position',new_similar_pos,'Visible','on');
  new_info_pos = [figpos(3) - info_pos(3) - handles.guidata.guipos.rightborder_rightpanels,...
    new_similar_pos(2) - info_pos(4) - dy_label_select,...
    info_pos(3:4)];
  set(handles.panel_selection_info,'Position',new_info_pos);
end


new_learn_pos = [figpos(3) - learn_pos(3) - handles.guidata.guipos.rightborder_rightpanels,...
  handles.guidata.guipos.bottomborder_bottompanels,...
  learn_pos(3:4)];
set(handles.panel_learn,'Position',...
  new_learn_pos);

function handles = GetGUIPositions(handles)

% all axes panels
handles.guidata.panel_previews = findobj(handles.figure_JLabel,'-regexp','Tag','panel_axes\d+');
% all preview axes
handles.guidata.axes_previews = findobj(handles.figure_JLabel,'Tag','axes_preview');
% all sliders
handles.guidata.slider_previews = findobj(handles.figure_JLabel,'Tag','slider_preview');
% all frame number edit boxes
handles.guidata.edit_framenumbers = findobj(handles.figure_JLabel,'Tag','edit_framenumber');
% all play buttons
handles.guidata.pushbutton_playstops = findobj(handles.figure_JLabel,'Tag','pushbutton_playstop');
% all timelines
handles.guidata.axes_timelines = findobj(handles.figure_JLabel,'-regexp','Tag','^axes_timeline.*')';
% handles.guidata.labels_timelines = findobj(handles.figure_JLabel,'-regexp','Tag','^timeline_label.*');
% Regex messes the order which makes it difficult to remove the last data axes.
handles.guidata.labels_timelines(1,1) = handles.timeline_label_prop1;
handles.guidata.labels_timelines(2,1) = handles.timeline_label_automatic;
handles.guidata.labels_timelines(3,1) = handles.timeline_label_manual;

handles.guidata.axes_timeline_props = findobj(handles.figure_JLabel,'-regexp','Tag','^axes_timeline_prop.*')';
handles.guidata.axes_timeline_labels = setdiff(handles.guidata.axes_timelines,handles.guidata.axes_timeline_props);

if numel(handles.guidata.labels_timelines) ~= numel(handles.guidata.labels_timelines),
  error('Number of timeline axes does not match number of timeline labels');
end
% sort by y-position
ys = nan(1,numel(handles.guidata.axes_timelines));
for i = 1:numel(handles.guidata.axes_timelines),
  pos = get(handles.guidata.axes_timelines(i),'Position');
  ys(i) = pos(2);
end
[~,order] = sort(ys);
handles.guidata.axes_timelines = handles.guidata.axes_timelines(order);
% sort by y-position. 
% Don't touch the last 2 labels that are part of manual and automatic timeline
% because they are inside a panel and so pos(2) is relative to the panel.
ys = nan(1,numel(handles.guidata.labels_timelines)-2);
for i = 1:(numel(handles.guidata.labels_timelines)-2),
  pos = get(handles.guidata.labels_timelines(i),'Position');
  ys(i) = pos(2);
end
[~,order] = sort(ys);
temp = handles.guidata.labels_timelines(1:end-2);
handles.guidata.labels_timelines(1:end-2) = temp(order);

handles.guidata.text_timeline_props = nan(size(handles.guidata.axes_timeline_props));
handles.guidata.text_timelines = nan(size(handles.guidata.axes_timelines));
[~,idx] = ismember(handles.guidata.axes_timeline_props,handles.guidata.axes_timelines);
for ii = 1:numel(handles.guidata.axes_timeline_props),
  i = idx(ii);
  t = get(handles.guidata.axes_timeline_props(ii),'Tag');
  m = regexp(t,'^axes_timeline_prop(.*)$','tokens','once');
  t2 = ['text_timeline_prop',m{1}];
  handles.guidata.text_timeline_props(ii) = handles.(t2);
  handles.guidata.text_timelines(i) = handles.guidata.text_timeline_props(ii);
end

figpos = get(handles.figure_JLabel,'Position');
panel_labelbuttons_pos = get(handles.panel_labelbuttons,'Position');
% panel_learn_pos = get(handles.panel_learn,'Position');
panel_timelines_pos = get(handles.panel_timelines,'Position');
panel_previews_pos = cell(size(handles.guidata.panel_previews));
for i = 1:numel(handles.guidata.panel_previews),
  panel_previews_pos{i} = get(handles.guidata.panel_previews(i),'Position');
end
handles.guidata.guipos.width_rightpanels = panel_labelbuttons_pos(3);
handles.guidata.guipos.rightborder_rightpanels = figpos(3) - (panel_labelbuttons_pos(1) + panel_labelbuttons_pos(3));
handles.guidata.guipos.leftborder_leftpanels = panel_timelines_pos(1);
handles.guidata.guipos.leftborder_rightpanels = panel_labelbuttons_pos(1) - (panel_timelines_pos(1) + panel_timelines_pos(3));
handles.guidata.guipos.topborder_toppanels = figpos(4) - (panel_labelbuttons_pos(2) + panel_labelbuttons_pos(4));
if handles.guidata.guipos.topborder_toppanels < 0
  handles.guidata.guipos.topborder_toppanels = 15;
end
handles.guidata.guipos.bottomborder_bottompanels = panel_timelines_pos(2);
handles.guidata.guipos.bottomborder_previewpanels = panel_previews_pos{end}(2) - (panel_timelines_pos(2)+panel_timelines_pos(4));
handles.guidata.guipos.frac_height_timelines = panel_timelines_pos(4) / (panel_timelines_pos(4) + panel_previews_pos{1}(4));

handles.guidata.guipos.timeline_bottom_borders = nan(1,numel(handles.guidata.axes_timelines));
handles.guidata.guipos.timeline_left_borders = nan(1,numel(handles.guidata.axes_timelines));
handles.guidata.guipos.timeline_label_middle_offsets = nan(1,numel(handles.guidata.axes_timelines));
pos0 = get(handles.guidata.axes_timelines(1),'Position');
handles.guidata.guipos.timeline_bottom_borders(1) = pos0(2);
handles.guidata.guipos.timeline_heights(1) = pos0(4);
handles.guidata.guipos.timeline_xpos = pos0(1);
handles.guidata.guipos.timeline_rightborder = panel_timelines_pos(3) - pos0(1) - pos0(3);
for i = 2:numel(handles.guidata.axes_timelines),
  pos1 = get(handles.guidata.axes_timelines(i),'Position');
  handles.guidata.guipos.timeline_bottom_borders(i) = pos1(2) - pos0(2) - pos0(4);
  handles.guidata.guipos.timeline_heights(i) = pos1(4);
  pos0 = pos1;
end
handles.guidata.guipos.timeline_top_border = panel_timelines_pos(4) - pos1(2) - pos1(4);
handles.guidata.guipos.timeline_heights = handles.guidata.guipos.timeline_heights / sum(handles.guidata.guipos.timeline_heights);
for i = 1:numel(handles.guidata.axes_timelines),
  ax_pos = get(handles.guidata.axes_timelines(i),'Position');
  label_pos = get(handles.guidata.labels_timelines(i),'Position');
  handles.guidata.guipos.timeline_left_borders(i) = label_pos(1);
  m = ax_pos(2) + ax_pos(4)/2;
  handles.guidata.guipos.timeline_label_middle_offsets(i) = label_pos(2)-m;
end
ax_pos = get(handles.axes_timeline_prop1,'Position');
handles.guidata.guipos.timeline_prop_height = ax_pos(4);
pos = get(handles.timeline_label_prop1,'Position');
handles.guidata.guipos.timeline_prop_label_left_border = pos(1);
handles.guidata.guipos.timeline_prop_label_size = pos(3:4);
handles.guidata.guipos.timeline_prop_label_callback = get(handles.timeline_label_prop1,'Callback');
handles.guidata.guipos.timeline_prop_fontsize = get(handles.timeline_label_prop1,'FontSize');
m = ax_pos(2) + ax_pos(4)/2;
handles.guidata.guipos.timeline_prop_label_middle_offset = pos(2)-m;

pos = get(handles.text_timeline_prop1,'Position');
handles.guidata.guipos.text_timeline_prop_right_border = ax_pos(1) - pos(1) - pos(3);
handles.guidata.guipos.text_timeline_prop_size = pos(3:4);
handles.guidata.guipos.text_timeline_prop_middle_offset = pos(2)-m;
handles.guidata.guipos.text_timeline_prop_fontsize = get(handles.text_timeline_prop1,'FontSize');
handles.guidata.guipos.text_timeline_prop_bgcolor = get(handles.text_timeline_prop1,'BackgroundColor');
handles.guidata.guipos.text_timeline_prop_fgcolor = get(handles.text_timeline_prop1,'ForegroundColor');

axes_pos = get(handles.axes_preview,'Position');
slider_pos = get(handles.slider_preview,'Position');
edit_pos = get(handles.edit_framenumber,'Position');
play_pos = get(handles.pushbutton_playstop,'Position');
handles.guidata.guipos.preview_axes_top_border = panel_previews_pos{end}(4) - axes_pos(4) - axes_pos(2);
handles.guidata.guipos.preview_axes_bottom_border = axes_pos(2);
handles.guidata.guipos.preview_axes_left_border = axes_pos(1);
handles.guidata.guipos.preview_axes_right_border = panel_previews_pos{end}(3) - axes_pos(1) - axes_pos(3);
handles.guidata.guipos.preview_slider_left_border = slider_pos(1);
handles.guidata.guipos.preview_slider_right_border = panel_previews_pos{end}(3) - slider_pos(1) - slider_pos(3);
handles.guidata.guipos.preview_slider_bottom_border = slider_pos(2);
handles.guidata.guipos.preview_play_left_border = play_pos(1) - slider_pos(1) - slider_pos(3);
handles.guidata.guipos.preview_play_bottom_border = play_pos(2);
handles.guidata.guipos.preview_edit_left_border = edit_pos(1) - play_pos(1) - play_pos(3);
handles.guidata.guipos.preview_edit_bottom_border = edit_pos(2);

% --- Executes when panel_timelines is resized.
function panel_timelines_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to panel_timelines (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.guidata.axes_timelines),
  return;
end
panel_pos = get(handles.panel_timelines,'Position');

ntimelines = numel(handles.guidata.axes_timelines);
h = panel_pos(4) - sum(handles.guidata.guipos.timeline_bottom_borders) - handles.guidata.guipos.timeline_top_border;
w = panel_pos(3) - handles.guidata.guipos.timeline_rightborder - handles.guidata.guipos.timeline_xpos;

y0 = 0;
for i = 1:ntimelines,
  y0 = y0 + handles.guidata.guipos.timeline_bottom_borders(i);
  axes_pos = [handles.guidata.guipos.timeline_xpos,y0,w,h*handles.guidata.guipos.timeline_heights(i)];
  m = axes_pos(2) + axes_pos(4)/2;
  set(handles.guidata.axes_timelines(i),'Position',axes_pos);
  label_pos = get(handles.guidata.labels_timelines(i),'Position');
  new_label_pos = [handles.guidata.guipos.timeline_left_borders(i),...
    m+handles.guidata.guipos.timeline_label_middle_offsets(i),...
    label_pos(3:4)];
  set(handles.guidata.labels_timelines(i),'Position',new_label_pos);
  if ishandle(handles.guidata.text_timelines(i)),
    new_text_pos = [axes_pos(1)-handles.guidata.guipos.text_timeline_prop_right_border-handles.guidata.guipos.text_timeline_prop_size(1),...
      m+handles.guidata.guipos.text_timeline_prop_middle_offset,...
      handles.guidata.guipos.text_timeline_prop_size];
    set(handles.guidata.text_timelines(i),'Position',new_text_pos);
  end
  y0 = y0 + axes_pos(4);
end

% Position for the auto and manual radio buttons.
timeline_select_pos = get(handles.panel_timeline_select,'Position');
timeline_manual_pos = get(handles.guidata.axes_timelines(end),'Position');
timeline_auto_pos = get(handles.guidata.axes_timelines(end-1),'Position');
timeline_select_pos(2) = timeline_auto_pos(2);
timeline_select_pos(4) = timeline_manual_pos(2)-timeline_auto_pos(2)+...
                            timeline_manual_pos(4);
set(handles.panel_timeline_select,'Position',timeline_select_pos);

auto_radio_pos = get(handles.timeline_label_automatic,'Position');
manual_radio_pos = get(handles.timeline_label_manual,'Position');
auto_radio_pos(2) = timeline_auto_pos(4)/2-auto_radio_pos(4)/2;
set(handles.timeline_label_automatic,'Position',auto_radio_pos);
manual_radio_pos(2) = timeline_select_pos(4)-auto_radio_pos(2)...
  -manual_radio_pos(4);
set(handles.timeline_label_manual,'Position',manual_radio_pos);


% Positions of the automatic timeline's labels
labelPredictionPos = get(handles.automaticTimelinePredictionLabel,'Position');
labelScoresPos =     get(handles.automaticTimelineScoresLabel,'Position');
popupBottomPos =     get(handles.automaticTimelineBottomRowPopup,'Position');
popupBottomPos(2) = timeline_auto_pos(2) + ...
  timeline_auto_pos(4)/6 - popupBottomPos(4)/2;
set(handles.automaticTimelineBottomRowPopup,'Position',popupBottomPos);
labelScoresPos(2) = timeline_auto_pos(2) + ...
  timeline_auto_pos(4)/2 - labelScoresPos(4)/2;
set(handles.automaticTimelineScoresLabel,'Position',labelScoresPos);
labelPredictionPos(2) = timeline_auto_pos(2) + ...
  5*timeline_auto_pos(4)/6 - labelPredictionPos(4)/2;
set(handles.automaticTimelinePredictionLabel,'Position',labelPredictionPos);

% Scores text position
scores_pos = get(handles.text_scores,'Position');
scores_pos(2) = popupBottomPos(2);
scores_pos(1) = auto_radio_pos(1)+auto_radio_pos(3)/2-scores_pos(3)/2;
set(handles.text_scores,'Position',scores_pos);


%{
% axes_manual_pos = [handles.guidata.guipos.timeline_xpos,...
%   panel_pos(4)-handles.guidata.guipos.timeline_bordery-h,w,h];
% set(handles.axes_timeline_manual,'Position',axes_manual_pos);  
% 
% axes_auto_pos = [handles.guidata.guipos.timeline_xpos,...
%   axes_manual_pos(2)-handles.guidata.guipos.timeline_bordery-h,w,h];
% set(handles.axes_timeline_auto,'Position',axes_auto_pos);  
% 
% text_manual_pos = get(handles.timeline_label_manual,'Position');
% m = axes_manual_pos(2) + axes_manual_pos(4)/2;
% new_text_manual_pos = [text_manual_pos(1),m - text_manual_pos(4)/2,...
%   text_manual_pos(3:4)];
% set(handles.timeline_label_manual,'Position',new_text_manual_pos);
% 
% text_auto_pos = get(handles.timeline_label_automatic,'Position');
% m = axes_auto_pos(2) + axes_auto_pos(4)/2;
% new_text_auto_pos = [text_auto_pos(1),m - text_auto_pos(4)/2,...
%   text_auto_pos(3:4)];
% set(handles.timeline_label_automatic,'Position',new_text_auto_pos);
%}

% --- Executes when panel_axes1 is resized.
function panel_axes1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to panel_axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.guidata.panel_previews),
  return;
end
previewi = find(handles.guidata.panel_previews==hObject,1);
if isempty(previewi), 
  return;
end

panel_pos = get(handles.guidata.panel_previews(previewi),'Position');

axes_pos = [handles.guidata.guipos.preview_axes_left_border,...
  handles.guidata.guipos.preview_axes_bottom_border,...
  panel_pos(3) - handles.guidata.guipos.preview_axes_left_border - handles.guidata.guipos.preview_axes_right_border,...
  panel_pos(4) - handles.guidata.guipos.preview_axes_top_border - handles.guidata.guipos.preview_axes_bottom_border];
set(handles.guidata.axes_previews(previewi),'Position',axes_pos);

max_ry = min(handles.guidata.zoom_fly_radius(1) * axes_pos(4) / axes_pos(3),handles.guidata.movie_height/2);
max_rx = min(handles.guidata.zoom_fly_radius(2) * axes_pos(3) / axes_pos(4),handles.guidata.movie_width/2);
ischange = false;
if max_ry > handles.guidata.zoom_fly_radius(2),
  handles.guidata.zoom_fly_radius(2) = max_ry;
  ischange = true;
elseif max_rx > handles.guidata.zoom_fly_radius(1),
  handles.guidata.zoom_fly_radius(1) = max_rx;
  ischange = true;
end
if ischange,
  guidata(hObject,handles);
  if strcmpi(handles.guidata.preview_zoom_mode,'center_on_fly'),
    ZoomInOnFlies(handles,previewi);
  elseif strcmpi(handles.guidata.preview_zoom_mode,'follow_fly'),
    KeepFliesInView(handles,previewi);
  end
end

slider_pos = get(handles.guidata.slider_previews(previewi),'Position');
new_slider_pos = [handles.guidata.guipos.preview_slider_left_border,...
  handles.guidata.guipos.preview_slider_bottom_border,...
  panel_pos(3) - handles.guidata.guipos.preview_slider_left_border - handles.guidata.guipos.preview_slider_right_border,...
  slider_pos(4)];
set(handles.guidata.slider_previews(previewi),'Position',new_slider_pos);

play_pos = get(handles.guidata.pushbutton_playstops(previewi),'Position');
new_play_pos = [new_slider_pos(1) + new_slider_pos(3) + handles.guidata.guipos.preview_play_left_border,...
  handles.guidata.guipos.preview_play_bottom_border,play_pos(3:4)];
set(handles.guidata.pushbutton_playstops(previewi),'Position',new_play_pos);


edit_pos = get(handles.guidata.edit_framenumbers(previewi),'Position');
new_edit_pos = [new_play_pos(1) + new_play_pos(3) + handles.guidata.guipos.preview_edit_left_border,...
  handles.guidata.guipos.preview_edit_bottom_border,edit_pos(3:4)];
set(handles.guidata.edit_framenumbers(previewi),'Position',new_edit_pos);


% --------------------------------------------------------------------
function menu_view_preview_options_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_preview_options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

prompts = {'Playback Speed (fps):','N. previous positions plotted:',...
  'N. future positions plotted:'};

while true,
  defaults = {num2str(handles.guidata.play_FPS),num2str(handles.guidata.traj_nprev),...
    num2str(handles.guidata.traj_npost)};
  res = inputdlg(prompts,'Preview Options',1,defaults);
  if isempty(res), return, end;
  errs = {};
  play_FPS = str2double(res{1});
  if isnan(play_FPS) || play_FPS <= 0,
    errs{end+1} = 'Playback speed must be a positive number'; %#ok<AGROW>
  else
    handles.guidata.play_FPS = play_FPS;
  end
  
  traj_nprev = str2double(res{2});
  if isnan(traj_nprev) || traj_nprev < 0 || rem(traj_nprev,1) ~= 0,
    errs{end+1} = 'N. previous positions plotted must be a postive integer'; %#ok<AGROW>
  else
    handles.guidata.traj_nprev = traj_nprev;
  end
  
  traj_npost = str2double(res{3});
  if isnan(traj_npost) || traj_npost < 0 || rem(traj_npost,1) ~= 0,
    errs{end+1} = 'N. future positions plotted must be a postive integer'; %#ok<AGROW>
  else
    handles.guidata.traj_npost = traj_npost;
  end
  
  if isempty(errs),
    break;
  else
    uiwait(warndlg(errs,'Bad preview options'));
  end
  
end
guidata(hObject,handles);
UpdatePlots(handles,...
  'refreshim',false,'refreshflies',false,'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',true,...
     'refresh_timeline_auto',false,...
     'refresh_timeline_suggest',false,...
     'refresh_timeline_error',true,...
     'refresh_timeline_xlim',false,...
     'refresh_timeline_hcurr',false,...
     'refresh_timeline_props',false,...
     'refresh_timeline_selection',false,...
     'refresh_curr_prop',false);


% --- Executes on button press in pushbutton_add_timeline.
function pushbutton_add_timeline_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_timeline (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

AddPropAxes(handles);

% --- Executes on selection change in timeline_label_prop1.
function timeline_label_prop1_Callback(hObject, eventdata, handles)
% hObject    handle to timeline_label_prop1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns timeline_label_prop1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from timeline_label_prop1
propi = GetTimelinePropNumber(hObject,handles);
v = get(hObject,'Value');
s = handles.guidata.timeline_prop_options{v};
if strcmpi(s,handles.guidata.timeline_prop_remove_string),
  RemovePropAxes(handles,propi);
elseif strcmpi(s,handles.guidata.timeline_prop_help_string),
  
  
else
  prop = find(strcmpi(s,handles.guidata.data.allperframefns),1);
  handles.guidata.perframepropis(propi) = prop;
  handles.perframeprops{propi} = s;
  [perframedata,T0,T1] = handles.guidata.data.GetPerFrameData(handles.guidata.expi,handles.guidata.flies,prop);
  set(handles.guidata.htimeline_data(propi),'XData',T0:T1,'YData',perframedata);
  ylim = [min(perframedata),max(perframedata)];
  if ylim(1) >= ylim(2)
    ylim(2) = ylim(1)+0.001;
  end
  set(handles.guidata.axes_timeline_props(propi),'YLim',ylim);
  zoom(handles.guidata.axes_timeline_props(propi),'reset');
  if ~isnan(handles.guidata.timeline_data_ylims(1,prop)),
    ylim = handles.guidata.timeline_data_ylims(:,prop);
    set(handles.guidata.axes_timeline_props(propi),'YLim',ylim);
  end
  ydata = [ylim(1)+diff(ylim)*.025,ylim(2)-diff(ylim)*.025];
  set(handles.guidata.hselection(propi),'YData',ydata([1,2,2,1,1]));
  s = sprintf('%.3f',perframedata(handles.guidata.ts(1)-T0+1));
  set(handles.guidata.text_timeline_props(propi),'String',s);
  guidata(hObject,handles);
end

function i = GetTimelinePropNumber(hObject,handles)

t = get(hObject,'Type');
if strcmpi(t,'axes'),
  i = find(hObject == handles.guidata.axes_timeline_props,1);
elseif strcmpi(t,'uicontrol'),
  s = get(hObject,'Style');
  if strcmpi(s,'popupmenu'),
    j = find(hObject == handles.guidata.labels_timelines,1);
    if isempty(j),
      i = [];
    else
      i = find(handles.guidata.axes_timelines(j) == handles.guidata.axes_timeline_props,1);
    end
  else
    i = [];
  end
else
  i = [];
end
if isempty(i),
  warning('Could not find index of parent panel');
  i = 1;
end

function handles = RemovePropAxes(handles,propi)

% which axes
axi = find(handles.guidata.axes_timelines == handles.guidata.axes_timeline_props(propi));

% how much height we will remove
axes_pos = get(handles.guidata.axes_timeline_props(propi),'Position');
hremove = axes_pos(4) + handles.guidata.guipos.timeline_bottom_borders(axi+1);

% set the sizes of the other axes to stretch
Z0 = sum(handles.guidata.guipos.timeline_heights);
Z1 = Z0 - handles.guidata.guipos.timeline_heights(axi);
handles.guidata.guipos.timeline_heights = handles.guidata.guipos.timeline_heights * Z0 / Z1;

% delete the axes
delete(handles.guidata.axes_timeline_props(propi));
delete(handles.guidata.labels_timelines(axi));
if ishandle(handles.guidata.text_timelines(axi)),
  delete(handles.guidata.text_timelines(axi));
end
handles.guidata.axes_timeline_props(propi) = [];
handles.guidata.axes_timelines(axi) = [];
handles.guidata.labels_timelines(axi) = [];
handles.guidata.text_timelines(axi) = [];
handles.guidata.text_timeline_props(propi) = [];
handles.guidata.htimeline_data(propi) = [];
handles.guidata.hcurr_timelines(axi) = [];
handles.guidata.hselection(axi) = [];
handles.guidata.guipos.timeline_bottom_borders(axi+1) = [];
handles.guidata.guipos.timeline_heights(axi) = [];
handles.guidata.guipos.timeline_left_borders(axi) = [];
handles.guidata.guipos.timeline_label_middle_offsets(axi) = [];
% handles.perframepropfns(propi) = [];
handles.guidata.perframepropis(propi) = [];

% show the xticks
set(handles.guidata.axes_timelines(1),'XTickLabelMode','auto');

guidata(handles.figure_JLabel,handles);

% make the panel smaller
panel_timelines_pos = get(handles.panel_timelines,'Position');
panel_timelines_pos(4) = panel_timelines_pos(4) - hremove;
set(handles.panel_timelines,'Position',panel_timelines_pos);

% make the preview panel bigger
panel_previews_pos = get(handles.guidata.panel_previews,'Position');
panel_previews_pos(2) = panel_previews_pos(2) - hremove;
panel_previews_pos(4) = panel_previews_pos(4) + hremove;
set(handles.guidata.panel_previews,'Position',panel_previews_pos);

handles = guidata(handles.figure_JLabel);

handles.guidata.guipos.frac_height_timelines = panel_timelines_pos(4) / (panel_timelines_pos(4) + panel_previews_pos(4));
guidata(handles.figure_JLabel,handles);


function handles = AddPropAxes(handles,prop)

% choose a property
if nargin < 2,
  prop = find(~ismember(1:numel(handles.guidata.data.allperframefns),handles.guidata.perframepropis),1);
  if isempty(prop),
    prop = 1;
  end
end
propi = numel(handles.guidata.axes_timeline_props)+1;
% how much height we will add
hadd = handles.guidata.guipos.timeline_prop_height + handles.guidata.guipos.timeline_bottom_borders(2);

% set the sizes of the other axes to shrink
panel_pos = get(handles.panel_timelines,'Position');
Z0 = panel_pos(4) - sum(handles.guidata.guipos.timeline_bottom_borders) - handles.guidata.guipos.timeline_top_border;
Z1 = Z0 + hadd;
handles.guidata.guipos.timeline_heights = handles.guidata.guipos.timeline_heights * Z0 / Z1;

% add the axes
w = panel_pos(3) - handles.guidata.guipos.timeline_rightborder - handles.guidata.guipos.timeline_xpos;
ax_pos = [handles.guidata.guipos.timeline_xpos,handles.guidata.guipos.timeline_bottom_borders(1),...
  w,handles.guidata.guipos.timeline_prop_height];
hax = axes('Parent',handles.panel_timelines,'Units','pixels',...
  'Position',ax_pos,'XColor','w','YColor','w',...
  'Color',get(handles.panel_timelines,'BackgroundColor'),...
  'Tag',sprintf('timeline_axes_prop%d',propi));
handles.guidata.axes_timeline_props = [hax,handles.guidata.axes_timeline_props];
handles.guidata.axes_timelines = [hax,handles.guidata.axes_timelines];
% fcn = get(handles.guidata.axes_timelines(1),'ButtonDownFcn');
% set(hax,'ButtonDownFcn',fcn);
setAxesZoomMotion(handles.guidata.hzoom,hax,'vertical');
hold(hax,'on');
[perframedata,T0,T1] = handles.guidata.data.GetPerFrameData(handles.guidata.expi,handles.guidata.flies,prop);
maxylim = [min(perframedata),max(perframedata)];
hdata = plot(T0:T1,perframedata,'w.-');
handles.guidata.htimeline_data = [hdata,handles.guidata.htimeline_data];
xlim = get(handles.guidata.axes_timelines(2),'XLim');
if isnan(handles.guidata.timeline_data_ylims(1,prop)),
  ylim = maxylim;
else
  ylim = handles.guidata.timeline_data_ylims(:,prop)';
end
set(hax,'XLim',xlim,'YLim',ylim);
zoom(hax,'reset');
hcurr = plot(hax,[0,0]+handles.guidata.ts(1),[-10^6,10^6],'y-','HitTest','off','linewidth',2);
handles.guidata.hcurr_timelines = [hcurr,handles.guidata.hcurr_timelines];
ydata = [ylim(1)+diff(ylim)*.025,ylim(2)-diff(ylim)*.025];
hselection = plot(hax,handles.guidata.selected_ts([1,1,2,2,1]),ydata([1,2,2,1,1]),'--',...
  'color',handles.guidata.selection_color,...
  'HitTest','off',...
  'LineWidth',3);
handles.guidata.hselection = [hselection,handles.guidata.hselection];
linkaxes(handles.guidata.axes_timelines,'x');

% add the label
m = ax_pos(2)+ax_pos(4)/2; 
pos = [handles.guidata.guipos.timeline_prop_label_left_border,...
  m+handles.guidata.guipos.timeline_prop_label_middle_offset,...
  handles.guidata.guipos.timeline_prop_label_size];
hlabel = uicontrol(handles.panel_timelines,...
  'Style','popupmenu',...
  'Units','pixels',...
  'BackgroundColor',get(handles.guidata.labels_timelines(1),'BackgroundColor'),...
  'ForegroundColor',get(handles.guidata.labels_timelines(1),'ForegroundColor'),...
  'String',handles.guidata.timeline_prop_options,...
  'Value',prop+2,...
  'Position',pos,...
  'FontUnits','pixels',...
  'FontSize',handles.guidata.guipos.timeline_prop_fontsize,...
  'Tag',sprintf('timeline_label_prop%d',propi));
set(hlabel,'Callback',@(hObject,eventdata) timeline_label_prop1_Callback(hObject,eventdata,guidata(hObject)));

handles.guidata.labels_timelines = [hlabel;handles.guidata.labels_timelines];

% add new axes sizes
handles.guidata.guipos.timeline_heights = [ax_pos(4) / Z1,handles.guidata.guipos.timeline_heights];
handles.guidata.guipos.timeline_bottom_borders = handles.guidata.guipos.timeline_bottom_borders([1,2,2:numel(handles.guidata.guipos.timeline_bottom_borders)]);
handles.guidata.guipos.timeline_left_borders = [pos(1),handles.guidata.guipos.timeline_left_borders];
handles.guidata.guipos.timeline_label_middle_offsets = [handles.guidata.guipos.timeline_prop_label_middle_offset,handles.guidata.guipos.timeline_label_middle_offsets];
% handles.perframepropfns = [handles.guidata.data.allperframefns(prop),handles.perframepropfns];
handles.guidata.perframepropis = [prop,handles.guidata.perframepropis];

% add the text box
pos = [ax_pos(1)-handles.guidata.guipos.text_timeline_prop_right_border-handles.guidata.guipos.text_timeline_prop_size(1),...
  m+handles.guidata.guipos.text_timeline_prop_middle_offset,...
  handles.guidata.guipos.text_timeline_prop_size];
htext = uicontrol(handles.panel_timelines,...
  'Style','text',...
  'Units','pixels',...
  'BackgroundColor',handles.guidata.guipos.text_timeline_prop_bgcolor,...
  'ForegroundColor',handles.guidata.guipos.text_timeline_prop_fgcolor,...
  'String','????????',...
  'Position',pos,...
  'FontUnits','pixels',...
  'FontSize',handles.guidata.guipos.text_timeline_prop_fontsize,...
  'Tag',sprintf('text_timeline_prop%d',propi),...
  'HorizontalAlignment','right');

handles.guidata.text_timeline_props = [htext;handles.guidata.text_timeline_props];
handles.guidata.text_timelines = [htext,handles.guidata.text_timelines];


% hide the xtick labels
set(handles.guidata.axes_timelines(2),'XTickLabel',{});


guidata(handles.figure_JLabel,handles);

% make the panel bigger
panel_timelines_pos = get(handles.panel_timelines,'Position');
panel_timelines_pos(4) = panel_timelines_pos(4) + hadd;
set(handles.panel_timelines,'Position',panel_timelines_pos);

% make the preview panel smaller
panel_previews_pos = get(handles.guidata.panel_previews,'Position');
panel_previews_pos(2) = panel_previews_pos(2) + hadd;
panel_previews_pos(4) = panel_previews_pos(4) - hadd;
set(handles.guidata.panel_previews,'Position',panel_previews_pos);

handles = guidata(handles.figure_JLabel);

handles.guidata.guipos.frac_height_timelines = panel_timelines_pos(4) / (panel_timelines_pos(4) + panel_previews_pos(4));

guidata(handles.figure_JLabel,handles);

UpdatePlots(handles,...
  'refreshim',false,'refreshflies',false,'refreshtrx',false,'refreshlabels',false,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_auto',false,...
  'refresh_timeline_suggest',false,...
  'refresh_timeline_error',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_props',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',true);


function PostZoomCallback(hObject,eventdata,handles)

timelinei = find(eventdata.Axes == handles.guidata.axes_timelines,1);
previewi = find(eventdata.Axes == handles.guidata.axes_previews,1);
if ~isempty(timelinei),
  prop = handles.guidata.perframepropis(timelinei);
  ylim = get(eventdata.Axes,'YLim');
  handles.guidata.timeline_data_ylims(:,prop) = ylim;
  ydata = [ylim(1)+diff(ylim)*.025,ylim(2)-diff(ylim)*.025];
  set(handles.guidata.hselection(timelinei),'YData',ydata([1,2,2,1,1]));
  guidata(eventdata.Axes,handles);
elseif ismember(eventdata.Axes,handles.guidata.axes_timeline_labels),
  xlim = get(eventdata.Axes,'XLim');
  handles.guidata.timeline_nframes = max(1,round(diff(xlim)-1)/2);
  guidata(eventdata.Axes,handles);
elseif ~isempty(previewi),
  xlim = get(eventdata.Axes,'XLim');
  ylim = get(eventdata.Axes,'YLim');
  rx = round((diff(xlim)-1)/2);
  ry = round((diff(ylim)-1)/2);
  axes_pos = get(eventdata.Axes,'Position');
  max_ry = min(rx * axes_pos(4) / axes_pos(3),handles.guidata.movie_height/2);
  max_rx = min(ry * axes_pos(3) / axes_pos(4),handles.guidata.movie_width/2);
  ischange = false;
  if max_ry > ry,
    ry = max_ry;
    ischange = true;
  elseif max_rx > rx,
    rx = max_rx;
    ischange = true;
  end
  if rx ~= handles.guidata.zoom_fly_radius(1) || ...
      ry ~= handles.guidata.zoom_fly_radius(2),
    handles.guidata.zoom_fly_radius = [rx,ry];
    guidata(eventdata.Axes,handles);
  end  
  if ischange,
    if strcmpi(handles.guidata.preview_zoom_mode,'center_on_fly'),
      ZoomInOnFlies(handles,previewi);
    elseif strcmpi(handles.guidata.preview_zoom_mode,'follow_fly'),
      KeepFliesInView(handles,previewi);
    end
  end
end


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure_JLabel_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure_JLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~handles.guidata.enabled,
  return;
end

hchil = gco;
if ismember(hchil,handles.guidata.axes_timelines),
  seltype = get(hObject,'SelectionType');
  switch lower(seltype),
    case 'normal', %left
      pt = get(hchil,'CurrentPoint');
      handles.guidata.buttondown_t0 = round(pt(1,1));
      handles.guidata.buttondown_axes = hchil;
      
      handles.guidata.didclearselection = ~any(isnan(handles.guidata.selected_ts));
      if handles.guidata.didclearselection,
        pushbutton_clearselection_Callback(hObject, eventdata, handles);
      else
        guidata(hObject,handles);
      end
      
      %fprintf('buttondown at %d\n',handles.guidata.buttondown_t0);
      %handles.guidata.selection_t0 = nan;
      %handles.guidata.selection_t1 = nan;

    case {'alternate','extend'}, %right,middle
      pt = get(hchil,'CurrentPoint');
      t = pt(1,1);
      if t >= handles.guidata.selected_ts(1) && t <= handles.guidata.selected_ts(2),
      end
    case 'open', % double click
  end
end


% --- Executes on mouse motion over figure - except title and menu.
function figure_JLabel_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to figure_JLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isfield(handles,'guidata') || ~ishandle(handles.guidata.buttondown_axes),
  return;
end
if ~isnan(handles.guidata.buttondown_t0) && isnan(handles.guidata.selection_t0) && ...
    isnan(handles.guidata.selection_t1),    
  handles.guidata.selection_t0 = handles.guidata.buttondown_t0;
  handles.guidata.buttondown_t0 = nan;
  if handles.guidata.selecting,
    set(handles.togglebutton_select,'Value',0);
    handles.guidata.selecting = false;
  end
  guidata(hObject,handles);
end
if ~isnan(handles.guidata.selection_t0),
  pt = get(handles.guidata.buttondown_axes,'CurrentPoint');
  handles.guidata.selection_t1 = round(pt(1,1));
  handles.guidata.selected_ts = [handles.guidata.selection_t0,handles.guidata.selection_t1];
  %fprintf('Selecting %d to %d\n',handles.guidata.selection_t0,handles.guidata.selection_t1);
  guidata(hObject,handles);
  UpdateSelection(handles);
end
  


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure_JLabel_WindowButtonUpFcn(hObject, eventdata, handles)
% hObject    handle to figure_JLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~ishandle(handles.guidata.buttondown_axes),
  return;
end
if isnan(handles.guidata.selection_t0),
  h = handles.guidata.buttondown_axes;
  handles.guidata.buttondown_axes = nan;
  handles.guidata.selection_t0 = nan;
  handles.guidata.selection_t1 = nan;
  if ~handles.guidata.didclearselection,
    axes_timeline_ButtonDownFcn(h, eventdata, handles);
  end
  return;
end
if ~isnan(handles.guidata.selection_t0),
  pt = get(handles.guidata.buttondown_axes,'CurrentPoint');
  handles.guidata.selection_t1 = round(pt(1,1));
  ts = sort([handles.guidata.selection_t0,handles.guidata.selection_t1]);
  ts(1) = min(max(ts(1),handles.guidata.t0_curr),handles.guidata.t1_curr);
  ts(2) = min(max(ts(2),handles.guidata.t0_curr),handles.guidata.t1_curr);
  if ts(1) == ts(2); % outside the range.
    handles.guidata.selected_ts = nan(1,2);
  else
    handles.guidata.selected_ts = ts;
  end
  %fprintf('Selected %d to %d\n',handles.guidata.selected_ts);
  UpdateSelection(handles);
end
handles.guidata.buttondown_axes = nan;
handles.guidata.selection_t0 = nan;
handles.guidata.selection_t1 = nan;
guidata(hObject,handles);

function UpdateSelection(handles)

tmp = handles.guidata.selected_ts + .5*[-1,1];
set(handles.guidata.hselection,'XData',tmp([1,1,2,2,1]));
buttons = [handles.pushbutton_playselection,handles.pushbutton_clearselection];
if any(isnan(handles.guidata.selected_ts)),
  set(buttons,'Enable','off');
else
  set(buttons,'Enable','on');
end

% --- Executes on button press in togglebutton_select.
function togglebutton_select_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton_select
if get(hObject,'Value'),
  
  set(handles.figure_JLabel,'WindowButtonMotionFcn',handles.guidata.callbacks.figure_WindowButtonMotionFcn);

%   handles.guidata.selecting = true;
%   handles.guidata.selected_ts = handles.guidata.ts(1)+[0,0];
%   handles.guidata.buttondown_axes = nan;
%   UpdateSelection(handles);
else
  set(handles.figure_JLabel,'WindowButtonMotionFcn','');
  handles.guidata.selecting = false;
end
guidata(hObject,handles);

% --- Executes on button press in pushbutton_clearselection.
function pushbutton_clearselection_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_clearselection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.guidata.hplaying == handles.pushbutton_playselection,
  handles = stopPlaying(handles);
end

handles.guidata.selected_ts = nan(1,2);
handles.guidata.buttondown_axes = nan;
handles.guidata.selection_t0 = nan;
handles.guidata.selection_t1 = nan;
guidata(hObject,handles);
UpdateSelection(handles);


% --- Executes on button press in pushbutton_playstop.
function pushbutton_playstop_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_playstop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% fprintf('In playstop\n');

if handles.guidata.hplaying == hObject,
  stopPlaying(handles);
else
  if ~isnan(handles.guidata.hplaying),
    stopPlaying(handles);
  end
  play(hObject,handles);
end

% --- Executes on button press in pushbutton_playselection.
function pushbutton_playselection_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_playselection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.guidata.hplaying == hObject,
  stopPlaying(handles);
else
  if ~isnan(handles.guidata.hplaying),
    stopPlaying(handles);
  end
  play(hObject,handles,handles.guidata.selected_ts(1),handles.guidata.selected_ts(2),true);
end

function predictTimerCallback(obj,event,hObject,framesPerTick)
  handles = guidata(hObject);
  if handles.guidata.data.IsGTMode(),
    return;
  end
  global PLAY_TIMER_DONE CALC_FEATURES;
  CALC_FEATURES = true;
  t0 = max(floor(handles.guidata.ts(1)-handles.guidata.timeline_nframes/2),handles.guidata.t0_curr);
  t1 = min(t0+framesPerTick,handles.guidata.t1_curr);
  handles.guidata.data.Predict(handles.guidata.expi,handles.guidata.flies,t0,t1);
  PLAY_TIMER_DONE = true;
  
function handles = play(hObject,handles,t0,t1,doloop)

clear global PLAY_TIME_DONE CALC_FEATURES
global PLAY_TIMER_DONE CALC_FEATURES;
PLAY_TIMER_DONE = false;
CALC_FEATURES = false;

axi = 1;
set(hObject,'String','Stop','BackgroundColor',[.5,0,0]);
SetButtonImage(handles.pushbutton_playstop);

if ~handles.guidata.data.IsGTMode()
  handles = UpdatePrediction(handles);
  guidata(hObject,handles);
end

handles.guidata.hplaying = hObject;
guidata(hObject,handles);
ticker = tic;
if nargin < 3,
  t0 = handles.guidata.ts(axi);
  t1 = handles.guidata.t1_curr;%nframes;
  doloop = false;
end

if ~doloop
  framesPerTick = 4000;
  t_period = round(framesPerTick/handles.guidata.play_FPS*1000)/1000;
  T = timer('TimerFcn',{@predictTimerCallback,hObject,framesPerTick},...
        'Period',t_period,...
        'ExecutionMode','fixedRate',...
        'Tag','predictTimer');
  start(T);
end

if(1)  % test framerate
while true,
  handles = guidata(hObject);
  if handles.guidata.hplaying ~= hObject,
    return;
  end
  
  if exist('CALC_FEATURES','var') && CALC_FEATURES
    t0 = handles.guidata.ts(axi);
    CALC_FEATURES = false;
  end
  
  if exist('PLAY_TIMER_DONE','var') && PLAY_TIMER_DONE
    ticker = tic;
    PLAY_TIMER_DONE = false;
    predictStart = max(handles.guidata.t0_curr,floor(handles.guidata.ts(1)-handles.guidata.timeline_nframes));
    predictEnd = min(handles.guidata.t1_curr,ceil(handles.guidata.ts(1)+handles.guidata.timeline_nframes/2));
    handles = SetPredictedPlot(handles);
    handles = UpdateTimelineIms(handles);

    guidata(hObject,handles);
    UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
      'refreshtrx',true,'refreshlabels',true,...
      'refresh_timeline_manual',false,...
      'refresh_timeline_xlim',false,...
      'refresh_timeline_hcurr',false,...
      'refresh_timeline_selection',false,...
      'refresh_curr_prop',false);

  end
  % how long has it been
  dt_sec = toc(ticker);
  % wait until the next frame should be played
  dt = dt_sec*handles.guidata.play_FPS;
  t = ceil(dt)+t0;
  if t > t1,
    if doloop,
      ticker = tic;
      continue;
    else
      break;
    end
  end
  SetCurrentFrame(handles,axi,t,hObject);
  handles = UpdateTimelineIms(handles);
  dt_sec = toc(ticker);
  pause_time = (t-t0)/handles.guidata.play_FPS - dt_sec;
  if pause_time <= 0,
    drawnow;
  else
    pause(pause_time);
  end
end

else  % test framerate

%t_last=t0;
t=t0;
while true,
  handles = guidata(hObject);
  if handles.guidata.hplaying ~= hObject,
    return;
  end
  
  if CALC_FEATURES
    t0 = handles.guidata.ts(axi);
    CALC_FEATURES = false;
  end
  
  if PLAY_TIMER_DONE
    ticker = tic;
    PLAY_TIMER_DONE = false;
    predictStart = max(handles.guidata.t0_curr,floor(handles.guidata.ts(1)-handles.guidata.timeline_nframes));
    predictEnd = min(handles.guidata.t1_curr,ceil(handles.guidata.ts(1)+handles.guidata.timeline_nframes/2));
    handles = SetPredictedPlot(handles);
    handles = UpdateTimelineIms(handles);

    guidata(hObject,handles);
    UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
      'refreshtrx',true,'refreshlabels',true,...
      'refresh_timeline_manual',false,...
      'refresh_timeline_xlim',false,...
      'refresh_timeline_hcurr',false,...
      'refresh_timeline_selection',false,...
      'refresh_curr_prop',false);

  end
  if t > t1,
    if doloop,
      ticker = tic;
      continue;
    else
      break;
    end
  end
  SetCurrentFrame(handles,axi,t,hObject);
  handles = UpdateTimelineIms(handles);
  drawnow;
if(exist('tocker'))  disp([num2str(1/toc(tocker),2)]);  end
tocker=tic;
%if(t-t_last>1)  disp(['skip ' num2str(t-t_last) ' @ ' num2str(t)]);  end
%if(t==t_last)  disp(['repeat @ ' num2str(t)]);  end
%t_last=t;
  t=t+1;
end

end  % test framerate

stopPlaying(handles);

function handles = stopPlaying(handles)

clear global PLAY_TIMER_DONE;
T = timerfind('Tag','predictTimer');
if ~isempty(T),  stop(T(:)); delete(T(:)); end
if isnan(handles.guidata.hplaying), return; end;
set(handles.guidata.hplaying,'String','Play','BackgroundColor',[.2,.4,0]);
SetButtonImage(handles.guidata.hplaying);
  
hObject = handles.guidata.hplaying;
handles.guidata.hplaying = nan;
guidata(hObject,handles);


% --------------------------------------------------------------------
function menu_view_plottracks_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_plottracks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

v = get(handles.menu_view_plottracks,'Checked');

if strcmpi(v,'on'),
  h = findall(handles.guidata.axes_previews,'Type','line','Visible','on');
  handles.tracks_visible = h;
  handles.doplottracks = false;
  set(h,'Visible','off');
  set(hObject,'Checked','off');
else
  handles.tracks_visible = handles.tracks_visible(ishandle(handles.tracks_visible));
  handles.doplottracks = true;
  set(handles.tracks_visible(:),'Visible','on');
  set(hObject,'Checked','on');
end
guidata(hObject,handles);


% --------------------------------------------------------------------
function contextmenu_timeline_manual_go_next_bout_start_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_manual_go_next_bout_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

menu_go_next_bout_start_Callback(hObject,eventdata,handles);


% --------------------------------------------------------------------
function contextmenu_timeline_manual_go_previous_bout_end_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_manual_go_previous_bout_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

menu_go_previous_bout_end_Callback(hObject,eventdata,handles);

function [t0,t1,labelidx,label] = GetBoutProperties(handles,t,labeltype)

if nargin < 3,
  labeltype = 'manual';
end

if t < handles.guidata.t0_curr && t > handles.guidata.t1_curr,
  t0 = nan;
  t1 = nan;
  labelidx = nan;
  label = '';
  return;
end

if strcmpi(labeltype,'manual'),
  [labelidxStruct,T0,T1] = handles.guidata.data.GetLabelIdx(handles.guidata.expi,handles.guidata.flies);
  labelidx = labelidxStruct.vals;
else
  [prediction,T0,T1] = handles.guidata.data.GetPredictedIdx(handles.guidata.expi,handles.guidata.flies);
  labelidx = prediction.predictedidx;
end
i = t - T0 + 1;
i0 = find(labelidx(1:i-1) ~= labelidx(i),1,'last');
if isempty(i0),
  t0 = T0;
else
  t0 = i0 + T0;
end
i1 = find(labelidx(i+1:end) ~= labelidx(i),1,'first');
if isempty(i1),
  t1 = T1;
else
  t1 = i1 + t - 1;
end
labelidx = labelidx(i);
if nargout >= 4,
  if labelidx == 0,
    label = 'Unknown';
  else
    label = handles.guidata.data.labelnames{labelidx};
  end
  if ~strcmpi(labeltype,'manual'),
    label = ['Predicted ',label];
  end
end

% --------------------------------------------------------------------
function contextmenu_timeline_manual_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_manual (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%disp('hi');
pt = get(handles.axes_timeline_manual,'CurrentPoint');
t = pt(1,1);

% inside a bout?
if t >= handles.guidata.t0_curr && t <= handles.guidata.t1_curr,
  [handles.bookmark_info.t0,handles.bookmark_info.t1,...
    handles.bookmark_info.labelidx,handles.bookmark_info.label] = ...
    GetBoutProperties(handles,round(t));
  s = sprintf('Bookmark %s bout (%d:%d)',handles.bookmark_info.label,...
    handles.bookmark_info.t0,handles.bookmark_info.t1);  
  set(handles.contextmenu_timeline_manual_bookmark_bout,'Visible','on',...
    'Label',s);
else
  set(handles.contextmenu_timeline_manual_bookmark_bout,'Visible','off');
end
  
% inside the current selection?
if t >= handles.guidata.selected_ts(1) && t <= handles.guidata.selected_ts(2),
  s = sprintf('Bookmark selection (%d:%d)',handles.guidata.selected_ts);
  handles.bookmark_info.t0 = min(handles.guidata.selected_ts);
  handles.bookmark_info.t1 = max(handles.guidata.selected_ts);
  handles.bookmark_info.labelidx = nan;
  handles.bookmark_info.label = 'Selection';
  set(handles.contextmenu_timeline_manual_bookmark_selection,'Visible','on','Label',s);
else
  set(handles.contextmenu_timeline_manual_bookmark_selection,'Visible','off');
end

guidata(hObject,handles);

% --------------------------------------------------------------------
function contextmenu_timeline_manual_bookmark_bout_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_manual_bookmark_bout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

clip = handles.bookmark_info;
clip.t0 = max(handles.guidata.t0_curr,clip.t0-1);
clip.t1 = min(clip.t1+1,handles.guidata.t1_curr);%nframes);
AddBookmark(handles,handles.bookmark_info);

% --------------------------------------------------------------------
function contextmenu_timeline_manual_bookmark_selection_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_manual_bookmark_selection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

labelidxStruct = handles.guidata.data.GetLabelIdx(handles.guidata.expi,handles.guidata.flies,handles.bookmark_info.t0,handles.bookmark_info.t1);
labelidx = labelidxStruct.vals;
handles.bookmark_info.labelidx = unique(labelidx);
tmp = [{'Unknown'},handles.guidata.data.labelnames];
if numel(handles.bookmark_info.labelidx) == 1,
  handles.bookmark_info.label = tmp{handles.bookmark_info.labelidx+1};
else
  counts = hist(labelidx,handles.bookmark_info.labelidx);
  pct = round(counts / numel(labelidx) * 100);
  s = '';
  for i = 1:numel(handles.bookmark_info.labelidx),
    s = [s,sprintf('%s(%d%%), ',tmp{handles.bookmark_info.labelidx(i)+1},pct(i))]; %#ok<AGROW>
  end
  s = s(1:end-2);
  handles.bookmark_info.label = s;
end
guidata(hObject,handles);

AddBookmark(handles,handles.bookmark_info);

function handles = AddBookmark(handles,clip)

fprintf('TODO: Create bookmark for %d:%d\n',clip.t0,clip.t1);
flystr = sprintf('%d, ',handles.guidata.flies);
flystr = flystr(1:end-2);
SetStatus(handles,sprintf('Saving AVI for experiment %s, %s %s, frames %d to %d...',...
  handles.guidata.data.expnames{handles.guidata.expi},handles.guidata.data.targettype,flystr,clip.t0,clip.t1));

handles = make_jlabel_results_movie(handles,clip.t0,clip.t1);
ClearStatus(handles);

%{
% clip.expi = handles.guidata.expi;
% clip.flies = handles.guidata.flies;
% clip.preview_zoom_mode = handles.guidata.preview_zoom_mode;
% axesi = 1;
% clip.xlim = get(handles.guidata.axes_previews(axesi),'XLim');
% clip.ylim = get(handles.guidata.axes_previews(axesi),'YLim');
% clip.zoom_fly_radius = handles.guidata.zoom_fly_radius;
% for i = 1:numel(handles.guidata.flies),
%   fly = handles.guidata.flies(i);
%   t0 = min(max(clip.t0,handles.guidata.t0_curr),handles.guidata.t1_curr);
%   t1 = min(max(clip.t1,handles.guidata.t0_curr),handles.guidata.t1_curr);
%   if t0 <= t1,
%     [xcurr,ycurr,thetacurr,acurr,bcurr] = ...
%       handles.guidata.data.GetTrxPos1(handles.guidata.expi,fly,t0:t1);
%   end
%   clip.trx(i).x = [nan(1,t0-clip.t0),xcurr,nan(1,clip.t1-t1)];
%   clip.trx(i).y = [nan(1,t0-clip.t0),ycurr,nan(1,clip.t1-t1)];
%   clip.trx(i).a = [nan(1,t0-clip.t0),acurr,nan(1,clip.t1-t1)];
%   clip.trx(i).b = [nan(1,t0-clip.t0),bcurr,nan(1,clip.t1-t1)];
%   clip.trx(i).theta = [nan(1,t0-clip.t0),thetacurr,nan(1,clip.t1-t1)];
% end
%  
% BookmarkedClips(handles.figure_JLabel,handles.guidata.data,'clips',clip);
%}


% --------------------------------------------------------------------
function contextmenu_timeline_manual_timeline_options_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_manual_timeline_options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

menu_view_timeline_options_Callback(hObject, eventdata, handles);


% --- Executes on button press in similarFramesButton.
function similarFramesButton_Callback(hObject, eventdata, handles)
% hObject    handle to similarFramesButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of similarFramesButton

handles = UpdatePrediction(handles);
curTime = handles.guidata.ts(1);
handles.guidata.data.SimilarFrames(curTime, handles);

function s = GetTargetInfo(handles,fly)

  s = {};
  i = 1;
  s{i} = sprintf('Target: %d',fly);
  i = i + 1;
  if handles.guidata.data.hassex,
    %t = max(handles.guidata.t0_curr,handles.guidata.ts(1));
    sexfrac = handles.guidata.data.GetSexFrac(handles.guidata.expi,fly);
    if sexfrac.M > sexfrac.F,
      sex = 'M';
    elseif sexfrac.M < sexfrac.F,
      sex = 'F';
    else
      sex = '?';
    end
    if handles.guidata.data.hasperframesex,
      s{i} = sprintf('Sex: %s (%d%%M, %d%%F)',sex,round(sexfrac.M*100),round(sexfrac.F*100));
    else
      s{i} = sprintf('Sex: %s',sex);
    end
    i = i + 1;
  end
  endframe = handles.guidata.data.endframes_per_exp{handles.guidata.expi}(fly);
  firstframe = handles.guidata.data.firstframes_per_exp{handles.guidata.expi}(fly);
  s{i} = sprintf('Frames: %d-%d',firstframe,endframe);
  i = i + 1;
  s{i} = sprintf(handles.guidata.data.expnames{handles.guidata.expi});


% --------------------------------------------------------------------
function menu_go_next_automatic_bout_start_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_next_automatic_bout_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% TODO: make this work with multiple preview axes
axesi = 1;

t = handles.guidata.NJObj.JumpToStart(handles.guidata.data,handles.guidata.expi,handles.guidata.flies,...
  handles.guidata.ts(axesi),handles.guidata.t0_curr,handles.guidata.t1_curr);
if isempty(t),  return; end

SetCurrentFrame(handles,axesi,t,hObject);

% --------------------------------------------------------------------
function menu_go_previous_automatic_bout_end_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_previous_automatic_bout_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% TODO: make this work with multiple preview axes
axesi = 1;

t = handles.guidata.NJObj.JumpToEnd(handles.guidata.data,handles.guidata.expi,handles.guidata.flies,...
  handles.guidata.ts(axesi),handles.guidata.t0_curr,handles.guidata.t1_curr);
if isempty(t); return; end

SetCurrentFrame(handles,axesi,t,hObject);


% --------------------------------------------------------------------
function menu_view_zoom_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_zoom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_view_zoom_keep_target_in_view_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_zoom_keep_target_in_view (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.guidata.preview_zoom_mode = 'follow_fly';
set(setdiff(handles.guidata.menu_view_zoom_options,hObject),'Checked','off');
set(hObject,'Checked','on');
KeepFliesInView(handles);
guidata(hObject,handles);

% --------------------------------------------------------------------
function menu_view_zoom_static_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_zoom_static (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.guidata.preview_zoom_mode = 'static';
set(setdiff(handles.guidata.menu_view_zoom_options,hObject),'Checked','off');
set(handles.menu_view_zoom_static,'Checked','on');
guidata(hObject,handles);


% --------------------------------------------------------------------
function contextmenu_timeline_automatic_go_next_bout_start_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_automatic_go_next_bout_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

menu_go_next_automatic_bout_start_Callback(hObject,eventdata,handles);

% --------------------------------------------------------------------
function contextmenu_timeline_automatic_go_previous_bout_end_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_automatic_go_previous_bout_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

menu_go_previous_automatic_bout_end_Callback(hObject,eventdata,handles);

% --------------------------------------------------------------------
function contextmenu_timeline_automatic_bookmark_bout_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_automatic_bookmark_bout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

clip = handles.bookmark_info;
clip.t0 = max(handles.guidata.t0_curr,clip.t0-1);
clip.t1 = min(clip.t1+1,handles.guidata.t1_curr);%nframes);
AddBookmark(handles,handles.bookmark_info);

% --------------------------------------------------------------------
function contextmenu_timeline_automatic_bookmark_selection_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_automatic_bookmark_selection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

prediction = handles.guidata.data.GetPredictedIdx(handles.guidata.expi,handles.guidata.flies,handles.bookmark_info.t0,handles.bookmark_info.t1);
labelidx = prediction.predictedidx;
handles.bookmark_info.labelidx = unique(labelidx);
tmp = [{'Unknown'},handles.guidata.data.labelnames];
if numel(handles.bookmark_info.labelidx) == 1,
  handles.bookmark_info.label = ['Predicted ',tmp{handles.bookmark_info.labelidx+1}];
else
  counts = hist(labelidx,handles.bookmark_info.labelidx);
  pct = round(counts / numel(labelidx) * 100);
  s = 'Predicted ';
  for i = 1:numel(handles.bookmark_info.labelidx),
    s = [s,sprintf('%s(%d%%), ',tmp{handles.bookmark_info.labelidx(i)+1},pct(i))]; %#ok<AGROW>
  end
  s = s(1:end-2);
  handles.bookmark_info.label = s;
end
guidata(hObject,handles);

AddBookmark(handles,handles.bookmark_info);

% --------------------------------------------------------------------
function contextmenu_timeline_automatic_timeline_options_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_automatic_timeline_options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

menu_view_timeline_options_Callback(hObject, eventdata, handles);

% --------------------------------------------------------------------
function contextmenu_timeline_automatic_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_automatic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

pt = get(handles.axes_timeline_auto,'CurrentPoint');
t = pt(1,1);

% inside a bout?
if t >= handles.guidata.t0_curr && t <= handles.guidata.t1_curr,
  [handles.bookmark_info.t0,handles.bookmark_info.t1,...
    handles.bookmark_info.labelidx,handles.bookmark_info.label] = ...
    GetBoutProperties(handles,round(t),'automatic');
  s = sprintf('Bookmark %s bout (%d:%d)',handles.bookmark_info.label,...
    handles.bookmark_info.t0,handles.bookmark_info.t1);  
  set(handles.contextmenu_timeline_automatic_bookmark_bout,'Visible','on',...
    'Label',s);
  s = sprintf('Accept %s bout (%d:%d)',handles.bookmark_info.label,...
    handles.bookmark_info.t0,handles.bookmark_info.t1);
  set(handles.contextmenu_timeline_automatic_accept_bout,'Visible','on',...
    'Label',s);
else
  set(handles.contextmenu_timeline_automatic_bookmark_bout,'Visible','off');
  set(handles.contextmenu_timeline_automatic_accept_bout,'Visible','off');
end
  
% inside the current selection?
if t >= handles.guidata.selected_ts(1) && t <= handles.guidata.selected_ts(2),
  s = sprintf('Bookmark selection (%d:%d)',handles.guidata.selected_ts);
  handles.bookmark_info.t0 = min(handles.guidata.selected_ts);
  handles.bookmark_info.t1 = max(handles.guidata.selected_ts);
  handles.bookmark_info.labelidx = nan;
  handles.bookmark_info.label = 'Selection';
  set(handles.contextmenu_timeline_automatic_bookmark_selection,'Visible','on','Label',s);
  s = sprintf('Accept selected suggested labels (%d:%d)',handles.guidata.selected_ts);
  set(handles.contextmenu_timeline_automatic_accept_selected,'Visible','on','Label',s);  
else
  set(handles.contextmenu_timeline_automatic_bookmark_selection,'Visible','off');
  set(handles.contextmenu_timeline_automatic_accept_selected,'Visible','off');
end

guidata(hObject,handles);


% --------------------------------------------------------------------
function contextmenu_timeline_automatic_accept_selected_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_automatic_accept_selected (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

t0 = handles.bookmark_info.t0;
t1 = handles.bookmark_info.t1;

t0 = min(handles.guidata.t1_curr,max(handles.guidata.t0_curr,t0));
t1 = min(handles.guidata.t1_curr,max(handles.guidata.t0_curr,t1));
prediction = handles.guidata.data.GetPredictedIdx(handles.guidata.expi,handles.guidata.flies,t0,t1);
predictedidx = prediction.predictedidx;
handles = SetLabelsPlot(handles,t0,t1,predictedidx);

UpdatePlots(handles,...
  'refreshim',false,'refreshflies',true,'refreshtrx',false,'refreshlabels',true,...
  'refresh_timeline_manual',true,...
  'refresh_timeline_auto',false,...
  'refresh_timeline_suggest',false,...
  'refresh_timeline_error',true,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_props',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);

guidata(hObject,handles);

% --------------------------------------------------------------------
function contextmenu_timeline_automatic_accept_bout_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_automatic_accept_bout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_view_plot_labels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_plot_labels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function handles = menu_view_plot_labels_manual_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_plot_labels_manual (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.guidata.plot_labels_manual = true;
handles.guidata.plot_labels_automatic = false;
% set(handles.panel_timeline_select,'SelectedObject',handles.timeline_label_manual);
set(handles.timeline_label_manual,'Value',1);
UpdatePlotLabels(handles);
guidata(hObject,handles);

% --------------------------------------------------------------------
function menu_view_plot_labels_automatic_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_plot_labels_automatic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.guidata.plot_labels_manual = false;
handles.guidata.plot_labels_automatic = true;
% set(handles.panel_timeline_select,'SelectedObject',handles.timeline_label_automatic);
set(handles.timeline_label_automatic,'Value',1);
UpdatePlotLabels(handles);
guidata(hObject,handles);

function UpdatePlotLabels(handles)

if handles.guidata.plot_labels_manual,
  set(handles.guidata.hlabels,'Visible','on');
  set(handles.menu_view_plot_labels_manual,'Checked','on');
  set(handles.timeline_label_manual,'ForegroundColor',handles.guidata.emphasiscolor,'FontWeight','bold');
else
  set(handles.guidata.hlabels,'Visible','off');
  set(handles.menu_view_plot_labels_manual,'Checked','off');
  set(handles.menu_view_plot_labels_manual,'Checked','off');
  set(handles.timeline_label_manual,'ForegroundColor',handles.guidata.unemphasiscolor,'FontWeight','normal');
end
if handles.guidata.plot_labels_automatic,
  set(handles.guidata.hpredicted,'Visible','on');
  set(handles.menu_view_plot_labels_automatic,'Checked','on');
  set(handles.timeline_label_automatic,'ForegroundColor',handles.guidata.emphasiscolor,'FontWeight','bold');
else
  set(handles.guidata.hpredicted,'Visible','off');
  set(handles.menu_view_plot_labels_automatic,'Checked','off');
  set(handles.timeline_label_automatic,'ForegroundColor',handles.guidata.unemphasiscolor,'FontWeight','normal');
end

UpdatePlots(handles,...
  'refreshim',false,'refreshflies',true,'refreshtrx',false,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_auto',false,...
  'refresh_timeline_suggest',false,...
  'refresh_timeline_error',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_props',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);


% --------------------------------------------------------------------
function contextmenu_timeline_automatic_overlay_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_automatic_overlay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

menu_view_plot_labels_automatic_Callback(hObject, eventdata, handles);

% --------------------------------------------------------------------
function contextmenu_timeline_manual_overlay_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_manual_overlay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

menu_view_plot_labels_manual_Callback(hObject, eventdata, handles);


% --------------------------------------------------------------------
function menu_view_show_bookmarked_clips_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_show_bookmarked_clips (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

clipdir = handles.guidata.data.GetFile('clipsdir',handles.guidata.expi);
if ispc,
  winopen(clipdir);
else
  web(clipdir,'-browser');
end


% --------------------------------------------------------------------
function menu_edit_compression_preferences_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_compression_preferences (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

CompressionPreferences(handles.figure_JLabel);

% --------------------------------------------------------------------
function menu_classifier_confThresholds_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_confThresholds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.guidata.data.ROCCurve(hObject);


% --------------------------------------------------------------------
function menu_classifier_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_classifier_classifyall_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classifyall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on button press in bagButton.
function bagButton_Callback(hObject, eventdata, handles)
% hObject    handle to bagButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.guidata.data.DoBagging();
set(handles.similarFramesButton,'Enable','on');


% --------------------------------------------------------------------
function menu_classifier_doFastUpdates_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_doFastUpdates (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curVal = get(hObject,'Checked');
if strcmp(curVal,'on')
  set(hObject,'Checked','off');
  handles.guidata.doFastUpdates = false;
else
  set(hObject,'Checked','on');
  handles.guidata.doFastUpdates = true;
end
guidata(hObject,handles);


% --------------------------------------------------------------------
function menu_classifier_selFeatures_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_selFeatures (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.guidata.data.ShowSelectFeatures();
handles = UpdatePrediction(handles);

if handles.guidata.data.NeedSaveProject();
  set(handles.menu_file_save_project,'Enable','on');
end

guidata(hObject,handles);

  
% --- Executes when selected object is changed in panel_timeline_select.
function panel_timeline_select_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panel_timeline_select 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

if  strcmp(get(eventdata.NewValue,'tag'),'timeline_label_manual')
  menu_view_plot_labels_manual_Callback(hObject, eventdata, handles);
else
  menu_view_plot_labels_automatic_Callback(hObject, eventdata, handles);
end


% --------------------------------------------------------------------
function crossValidate_Callback(hObject, eventdata, handles)
% hObject    handle to crossValidate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.guidata.data.StoreLabels();
[success,msg,crossError,tlabels] = handles.guidata.data.CrossValidate();

if ~success, warndlg(msg); 
  return; 
end;

contents = cellstr(get(handles.automaticTimelineBottomRowPopup,'String'));
handles.guidata.bottomAutomatic = 'Validated';
set(handles.automaticTimelineBottomRowPopup,'Value',...
find(strcmp(contents,handles.guidata.bottomAutomatic)));

handles = SetPredictedPlot(handles);
handles = UpdatePrediction(handles);
guidata(hObject,handles);



cnames = {sprintf('%s|Predicted',handles.guidata.data.labelnames{1}),...
          'Not|Predicted',...
          sprintf('%s|Predicted',handles.guidata.data.labelnames{2}),...
          };
rnames = {sprintf('%s Important ',handles.guidata.data.labelnames{1}),...
          sprintf('%s Important ',handles.guidata.data.labelnames{2}),...
          '',...
          sprintf('Old %s Important',handles.guidata.data.labelnames{1}),...
          sprintf('Old %s Important',handles.guidata.data.labelnames{2}),...
          };

dat = {};
for col = 1:3
  for row = 1:4
    t1 = sprintf('%d ',crossError(1).numbers(row,col));
    if isnan(crossError(1).frac(row,col))
      t2 = ' (-)';
    else
      t2 = sprintf(' (%.1f%%)',crossError(1).frac(row,col)*100);
    end
    dat{row,col} = sprintf('%s%s',t1,t2);
  end
end

dat(5,:) = repmat({''},1,3);

for col = 1:3
  for row = 1:4
    t1 = sprintf('%d ',crossError(1).oldNumbers(row,col));
    if isnan(crossError(1).oldFrac(row,col))
      t2 = ' (-)';
    else
      t2 = sprintf(' (%.1f%%)',crossError(1).oldFrac(row,col)*100);
    end
    dat{5+row,col} = sprintf('%s%s',t1,t2);
  end
end
        
f = figure('Position',[200 200 550 140],'Name','Cross Validation Error');
t = uitable('Parent',f,'Data',dat([1 3 5 6 8],:),'ColumnName',cnames,... 
            'ColumnWidth',{100},...
            'RowName',rnames,'Units','normalized','Position',[0 0 0.99 0.99]);

handles.guidata.open_peripherals(end+1) = f;          
if numel(crossError)>1
  for tndx = 1:numel(crossError)
    errorAll(tndx,1) = crossError(tndx).numbers(2,3)+crossError(tndx).numbers(4,1);
    errorImp(tndx,1) = crossError(tndx).numbers(1,3)+crossError(tndx).numbers(3,1);
  end
  totExamplesAll = sum(crossError(1).numbers(2,:))+sum(crossError(1).numbers(4,:));
  totExamplesImp = sum(crossError(1).numbers(1,:))+sum(crossError(1).numbers(3,:));

  errorAll = errorAll/totExamplesAll;
  errorImp = errorImp/totExamplesImp;

  f = figure('Name','Cross Validation Error with time');
  ax = plot([errorAll errorImp]);
  legend(ax,{'All', 'Important'});
  set(gca,'XTick',1:numel(errorAll),'XTickLabel',tlabels,'XDir','reverse');
  title(gca,'Cross Validation Error with time');
  handles.guidata.open_peripherals(end+1) = f;          
end

% --------------------------------------------------------------------
function menu_classifier_classifyCurrentFly_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classifyCurrentFly (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
t0 =handles.guidata.t0_curr;
t1 = handles.guidata.t1_curr;
handles.guidata.data.Predict(handles.guidata.expi,handles.guidata.flies,handles.guidata.t0_curr,handles.guidata.t1_curr);
handles = SetPredictedPlot(handles,t0,t1);

handles = UpdateTimelineIms(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);


% --------------------------------------------------------------------
function menu_file_loadScores_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_loadScores (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_file_loadscorescurrentexpdefault_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_loadscorescurrentexpdefault (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.guidata.data.LoadScoresDefault(handles.guidata.data.expi);

contents = cellstr(get(handles.automaticTimelineBottomRowPopup,'String'));
handles.guidata.bottomAutomatic = 'Loaded';
set(handles.automaticTimelineBottomRowPopup,'Value',...
find(strcmp(contents,handles.guidata.bottomAutomatic)));

handles = UpdateTimelineIms(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);


% --------------------------------------------------------------------
function menu_file_loadscorescurrentexpselect_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_loadscorescurrentexpselect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tstring = sprintf('Scores file for %s',handles.guidata.data.expnames{handles.guidata.data.expi});
[fname,pname,~] = uigetfile('*.mat',tstring);
if ~fname; return; end;
sfn = fullfile(pname,fname);
handles.guidata.data.LoadScores(handles.guidata.data.expi,sfn);

contents = cellstr(get(handles.automaticTimelineBottomRowPopup,'String'));
handles.guidata.bottomAutomatic = 'Loaded';
set(handles.automaticTimelineBottomRowPopup,'Value',...
find(strcmp(contents,handles.guidata.bottomAutomatic)));

handles = UpdateTimelineIms(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);

% --------------------------------------------------------------------
function menu_file_loadscorescurrentexprootdir_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_loadscorescurrentexprootdir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tstring = sprintf('Root dir to load scores for current experiment');
fname = uigetdir('*.mat',tstring);
if ~fname; return; end;
scoreFileName = handles.guidata.data.GetFile('scores',handles.guidata.expi);
[~, scoreFileName, ext] = myfileparts(scoreFileName);
sfn = fullfile(fname,handles.guidata.data.expnames{handles.guidata.expi},[scoreFileName ext]);
if ~exist(sfn,'file')
  warndlg(sprintf('Scores file %s does not exist for exp:%s',...
    scoreFileName,handles.guidata.data.expnames{handles.guidata.expi}));
  return;
end
handles.guidata.data.LoadScores(handles.guidata.expi,sfn);

contents = cellstr(get(handles.automaticTimelineBottomRowPopup,'String'));
handles.guidata.bottomAutomatic = 'Loaded';
set(handles.automaticTimelineBottomRowPopup,'Value',...
find(strcmp(contents,handles.guidata.bottomAutomatic)));

handles = UpdateTimelineIms(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);


% --------------------------------------------------------------------
function menu_file_loadscoresAlldefault_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_loadscoresAlldefault (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
for ndx = 1:handles.guidata.data.nexps,
  handles.guidata.data.LoadScoresDefault(ndx);
end

contents = cellstr(get(handles.automaticTimelineBottomRowPopup,'String'));
handles.guidata.bottomAutomatic = 'Loaded';
set(handles.automaticTimelineBottomRowPopup,'Value',...
find(strcmp(contents,handles.guidata.bottomAutomatic)));

handles = UpdateTimelineIms(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);


% --------------------------------------------------------------------
function menu_file_loadscoresAllselect_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_loadscoresAllselect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

tstring = sprintf('Root dir to load scores for all experiments');
fname = uigetdir('*.mat',tstring);
if ~fname; return; end;
scoreFileName = handles.guidata.data.GetFile('scores',handles.guidata.expi);
[~, scoreFileName, ext] = myfileparts(scoreFileName);
scoreFileName = [scoreFileName ext];

for ndx = 1:handles.guidata.data.nexps,
  sfn = fullfile(fname,handles.guidata.data.expnames{ndx},scoreFileName);
  if ~exist(sfn,'file')
    warndlg(sprintf('Scores file %s does not exist for exp:%s',...
      scoreFileName,handles.guidata.data.expnames{ndx}));
    continue; 
  end
  handles.guidata.data.LoadScores(ndx,sfn);
end

contents = cellstr(get(handles.automaticTimelineBottomRowPopup,'String'));
handles.guidata.bottomAutomatic = 'Loaded';
set(handles.automaticTimelineBottomRowPopup,'Value',...
find(strcmp(contents,handles.guidata.bottomAutomatic)));

handles = UpdateTimelineIms(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);


% --------------------------------------------------------------------
function menu_classifier_testnewlabels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_testnewlabels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

newError = handles.guidata.data.TestOnNewLabels();
handles = UpdatePrediction(handles);
if ~isfield(newError,'numbers'), return; end;
dialogStr = {};
if isfield(newError,'classifierfilename'),
  dialogStr{end+1} = sprintf('Classifier used to generate scores:%s',newError.classifierfilename);
end
dialogStr{end+1} = sprintf('%28s Predicted %10s    Predicted %10s \n',...
  '',handles.guidata.data.labelnames{2},handles.guidata.data.labelnames{1});
dialogStr{end+1} = sprintf('Labeled Important %12s      %d(%.2f)          %d(%.2f)\n',...
  handles.guidata.data.labelnames{1},...
  newError.numbers(1,1),newError.frac(1,1),...
  newError.numbers(1,3),newError.frac(1,3));
dialogStr{end+1} = sprintf('Labeled            %12s      %d(%.2f)          %d(%.2f)\n',...
  handles.guidata.data.labelnames{1},...
  newError.numbers(2,1),newError.frac(2,1),...
  newError.numbers(2,3),newError.frac(2,3));
dialogStr{end+1} = sprintf('Labeled Important  %12s      %d(%.2f)          %d(%.2f)\n',...
  handles.guidata.data.labelnames{2},...
  newError.numbers(3,1),newError.frac(3,1),...
  newError.numbers(3,3),newError.frac(3,3));
dialogStr{end+1} = sprintf('Labeled            %12s      %d(%.2f)          %d(%.2f)\n',...
  handles.guidata.data.labelnames{2},...
  newError.numbers(4,1),newError.frac(4,1),...
  newError.numbers(4,3),newError.frac(4,3));

helpdlg(dialogStr,'Performance on new labeled data');


% --------------------------------------------------------------------
function menu_file_load_exps_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_load_exps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filename = handles.guidata.data.classifierfilename;
[filename,pathname] = uigetfile('*.mat','Load classifier',filename);
if ~ischar(filename),
  return;
end
classifiername = fullfile(pathname,filename);
handles.guidata.data.SetClassifierFileName(classifiername);


% --------------------------------------------------------------------
function menu_file_load_woexps_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_load_woexps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

filename = handles.guidata.data.classifierfilename;
[filename,pathname] = uigetfile('*.mat','Load classifier',filename);
if ~ischar(filename),
  return;
end
classifiername = fullfile(pathname,filename);
handles.guidata.data.SetClassifierFileNameWoExp(classifiername);


% --------------------------------------------------------------------
function menu_classifier_setclassifierparameters_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_setclassifierparameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cohandles = ClassifierOptions(handles.guidata.data);
handles.guidata.open_peripherals(end+1) = cohandles;

% --------------------------------------------------------------------
function menu_go_switch_target_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_switch_target (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
changeTargetHandle = SwitchTarget(hObject);
SwitchTarget('initTable',changeTargetHandle);
handles.guidata.open_peripherals(end+1) = changeTargetHandle;


% --------------------------------------------------------------------
function menu_classifier_visualize_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_visualize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

SetStatus(handles,'Creating classifier visualization');

[hweight,hscore,hax,hfig,hylabel,hticks,hcolorbar,...
  sorted_weights,feature_order,bins,scores] = ...
  ShowWindowFeatureWeights(handles.guidata.data,'figpos',...
  [10,10,1000,1000],'nfeatures_show',50); %#ok<ASGLU>

ti = sprintf('Classifier %s',datestr(handles.guidata.data.classifierTS));
set(hfig,'Name',ti);

handles.visualizeclassifier = ...
  struct('sorted_weights',sorted_weights,...
  'feature_order',feature_order,'bins',bins,...
  'scores',scores);

handles.guidata.open_peripherals(end+1) = hfig;

guidata(hObject,handles);

ClearStatus(handles);


% --------------------------------------------------------------------
function menu_classifier_classify_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classify (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_classifier_classifyCurrentMovie_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classifyCurrentMovie (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes on selection change in automaticTimelineBottomRowPopup.
function automaticTimelineBottomRowPopup_Callback(hObject, eventdata, handles)
% hObject    handle to automaticTimelineBottomRowPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

contents = cellstr(get(hObject,'String'));
handles.guidata.bottomAutomatic = contents{get(hObject,'Value')};
set(handles.automaticTimelineBottomRowPopup,'BackgroundColor',[50 50 50]/256);
handles = UpdateTimelineIms(handles);
guidata(hObject,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);



% --- Executes during object creation, after setting all properties.
function automaticTimelineBottomRowPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to automaticTimelineBottomRowPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function handles = UpdateGUIGroundTruthMode(handles)

% things that are invisible in groundtruth-mode
hinv_gt = [handles.pushbutton_train,...
  ...handles.pushbutton_predict,...
  handles.axes_timeline_auto,handles.guidata.himage_timeline_auto,...
  handles.guidata.htimeline_errors,handles.guidata.htimeline_suggestions,...
  handles.automaticTimelinePredictionLabel,...
  handles.automaticTimelineScoresLabel,...
  handles.automaticTimelineBottomRowPopup,...
  handles.timeline_label_automatic,...
  handles.menu_edit_guimode];
hvisible_gt = [handles.menu_view_showPredictions, ...
  handles.menu_view_suggest,...
  handles.menu_classifier_gt_performance];

if handles.guidata.data.nexps < 1,
  return;
end

if handles.guidata.data.IsGTMode()
  set(hinv_gt,'Visible','off');
  set(hvisible_gt,'Visible','on');
  % go to advanced mode
  handles = menu_view_plot_labels_manual_Callback(handles.panel_timeline_select, [], handles);
else
  set(hinv_gt,'Visible','on');
  set(hvisible_gt,'Visible','off');
  % go to Normal mode
end
handles = UpdateGUIAdvancedMode(handles);

function handles = UpdateGUIAdvancedMode(handles)

SetGUIModeMenuChecks(handles);

% in the right mode already?

if ~handles.guidata.data.IsAdvancedMode() || handles.guidata.data.IsGTMode(),
  set(handles.panel_similar,'Visible','off');
else
  set(handles.panel_similar,'Visible','on');
end

if handles.guidata.GUIAdvancedMode == handles.guidata.data.IsAdvancedMode()
   return;
end

% get positions of stuff
set(handles.panel_labelbuttons,'Units','pixels');
panel_pos = get(handles.panel_labelbuttons,'Position');
select_pos = get(handles.panel_select,'Position');
if ishandle(handles.togglebutton_label_behavior1)
  set(handles.togglebutton_label_behavior1,'Units','pixels');
end
if ~isnan(handles.guidata.togglebutton_label_behaviors(end))
  button1_pos = get(handles.guidata.togglebutton_label_behaviors(end),'Position');
else
  button1_pos = get(handles.guidata.togglebutton_label_behaviors(end-1),'Position');
end  
set(handles.togglebutton_label_unknown,'Units','pixels');
unknown_button_pos = get(handles.togglebutton_label_unknown,'Position');
out_border_y = unknown_button_pos(2);
out_border_x = unknown_button_pos(1);
in_border_y = button1_pos(2) - (unknown_button_pos(2)+unknown_button_pos(4));
button_width = button1_pos(3);
button_height = button1_pos(4);

% calculate new height for the panel
if ~handles.guidata.data.IsAdvancedMode();
new_panel_height = 2*out_border_y + (handles.guidata.data.nbehaviors+1)*button_height + ...
  handles.guidata.data.nbehaviors*in_border_y;
else
new_panel_height = 2*out_border_y + (2*handles.guidata.data.nbehaviors+1)*button_height + ...
  2*handles.guidata.data.nbehaviors*in_border_y;
end

% update panel position
panel_top = panel_pos(2)+panel_pos(4);
new_panel_pos = [panel_pos(1),panel_top-new_panel_height,panel_pos(3),new_panel_height];
set(handles.panel_labelbuttons,'Position',new_panel_pos);
dy_label_select = panel_pos(2) - select_pos(2) - select_pos(4);
new_select_pos = [select_pos(1),new_panel_pos(2)-select_pos(4)-dy_label_select,select_pos(3:4)];
set(handles.panel_select,'Position',new_select_pos);

figure_JLabel_ResizeFcn(handles.panel_labelbuttons, [], handles);

% move unknown button to the bottom
new_unknown_button_pos = [unknown_button_pos(1),out_border_y,unknown_button_pos(3),button_height];
set(handles.togglebutton_label_unknown,'Position',new_unknown_button_pos);

% create or remove buttons
if ~handles.guidata.data.IsAdvancedMode(),
  % delete extra buttons
  h = handles.guidata.togglebutton_label_behaviors(2:2:end);
  h = h(ishandle(h));
  if ~isempty(h),
    delete(h);
  end
  handles.guidata.togglebutton_label_behaviors(2:2:end) = nan;
else
  % create extra buttons
  for i = 1:handles.guidata.data.nbehaviors,
    pos = [out_border_x,new_panel_height-out_border_y-button_height*(2*i-1)-in_border_y*(2*i-2),...
      button_width,button_height];
    handles.guidata.togglebutton_label_behaviors(2*i) = ...
      uicontrol('Style','togglebutton','String',sprintf('Important %s',handles.guidata.data.labelnames{i}),...
      'ForegroundColor','w','Units','pixels','FontUnits','pixels','FontSize',14,...
      'FontWeight','bold','BackgroundColor',ShiftColor.decreaseIntensity(handles.guidata.labelcolors(i,:)),...
      'Position',pos,...
      'Callback',get(handles.guidata.togglebutton_label_behaviors(1),'Callback'),...
      'Parent',handles.panel_labelbuttons,...
      'Tag',sprintf('togglebutton_label_behavior%d',i),...
      'UserData',2*i);
  end
end

% update the buttons
for i = 1:handles.guidata.data.nbehaviors,
  if handles.guidata.data.IsAdvancedMode(),
    pos = [out_border_x,new_panel_height-out_border_y-button_height*(2*i-1)-in_border_y*(2*i-2),...
      button_width,button_height];
    set(handles.guidata.togglebutton_label_behaviors(2*i-1),...
      'String',sprintf('Important %s',handles.guidata.data.labelnames{i}),...
      'ForegroundColor','w','Units','pixels','FontUnits','pixels','FontSize',14,...
      'FontWeight','bold','BackgroundColor',handles.guidata.labelcolors(i,:),...
      'Position',pos,...
      'Callback',get(handles.guidata.togglebutton_label_behaviors(1),'Callback'),...
      'Parent',handles.panel_labelbuttons,...
      'Tag',sprintf('togglebutton_label_behavior%d',i),...
      'UserData',2*i-1);
    SetButtonImage(handles.guidata.togglebutton_label_behaviors(2*i-1));
    pos = [out_border_x,new_panel_height-out_border_y-button_height*(2*i)-in_border_y*(2*i-1),...
      button_width,button_height];
    set(handles.guidata.togglebutton_label_behaviors(2*i),...
      'String',sprintf('%s',handles.guidata.data.labelnames{i}),...
      'ForegroundColor','w','Units','pixels','FontUnits','pixels','FontSize',14,...
      'FontWeight','bold','BackgroundColor',ShiftColor.decreaseIntensity(handles.guidata.labelcolors(i,:)),...
      'Position',pos,...
      'Callback',get(handles.guidata.togglebutton_label_behaviors(1),'Callback'),...
      'Parent',handles.panel_labelbuttons,...
      'Tag',sprintf('togglebutton_label_normbehavior%d',i),...
      'UserData',2*i);
    SetButtonImage(handles.guidata.togglebutton_label_behaviors(2*i));
  else
    pos = [out_border_x,new_panel_height-out_border_y-button_height*i-in_border_y*(i-1),...
      button_width,button_height];
    set(handles.guidata.togglebutton_label_behaviors(2*i-1),...
      'String',sprintf('%s',handles.guidata.data.labelnames{i}),...
      'ForegroundColor','w','Units','pixels','FontUnits','pixels','FontSize',14,...
      'FontWeight','bold','BackgroundColor',handles.guidata.labelcolors(i,:),...
      'Position',pos,...
      'Callback',get(handles.guidata.togglebutton_label_behaviors(1),'Callback'),...
      'Parent',handles.panel_labelbuttons,...
      'Tag',sprintf('togglebutton_label_normbehavior%d',i),...
      'UserData',2*i-1);
    SetButtonImage(handles.guidata.togglebutton_label_behaviors(2*i-1));
  end
  
end

% set props for unknown button
set(handles.togglebutton_label_unknown,...
  'String','Unknown',...
  'ForegroundColor','w','Units','pixels','FontUnits','pixels','FontSize',14,...
  'FontWeight','bold','BackgroundColor',handles.guidata.labelunknowncolor,...
  'UserData',-1);
SetButtonImage(handles.togglebutton_label_unknown);

handles.guidata.GUIAdvancedMode = handles.guidata.data.IsAdvancedMode;

% --------------------------------------------------------------------
function menu_edit_guimode_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_guimode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_edit_guimode_basictraining_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_guimode_basictraining (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.guidata.data.SetGTMode(false);
handles.guidata.data.SetAdvancedMode(false);
handles = UpdateGUIGroundTruthMode(handles);
guidata(hObject,handles);

% --------------------------------------------------------------------
function menu_edit_guimode_advancedtraining_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_guimode_advancedtraining (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.guidata.data.SetGTMode(false);
handles.guidata.data.SetAdvancedMode(true);
handles = UpdateGUIGroundTruthMode(handles);
guidata(hObject,handles);

% --------------------------------------------------------------------
function menu_edit_guimode_groundtruthing_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_guimode_groundtruthing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.guidata.data.SetGTMode(true);
handles = UpdateGUIGroundTruthMode(handles);
guidata(hObject,handles);


% --------------------------------------------------------------------
function menu_view_showPredictions_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_showPredictions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

h_prediction = [handles.axes_timeline_auto,handles.guidata.himage_timeline_auto,...
    handles.automaticTimelinePredictionLabel,...
    handles.automaticTimelineScoresLabel,...
    handles.automaticTimelineBottomRowPopup,...
    handles.timeline_label_automatic];

if strfind(get(hObject,'Label'),'Show')
  set(hObject,'Label','Hide Predictions');
  set(h_prediction,'Visible','on');
else
  set(hObject,'Label','Show Predictions');
  set(h_prediction,'Visible','off');  
end

set(handles.menu_view_plot_labels_automatic,'Visible','on');



% --------------------------------------------------------------------
function menu_view_suggest_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_suggest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_view_suggest_random_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_suggest_random (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

in = inputdlg({'Number of frames per fly','Number of flies per experiment'});
perfly = str2double(in{1});
perexp = str2double(in{2});
if isnan(perfly) || (round(perfly)-perfly)~=0 || ...
    isnan(perexp) || (round(perexp)-perexp)~=0 
  warndlg('Input error: enter integer values');
  return;
end

if any( handles.guidata.data.nflies_per_exp<perexp)
  warndlg('Some experiments have less than %d flies\n',perexp);
  return;
end

handles.guidata.data.SuggestRandomGT(perfly,perexp);

set(handles.menu_view_suggest_random,'Checked','on');
set(handles.menu_view_suggest_threshold,'Checked','off');
set(handles.menu_view_suggest_file,'Checked','off');
set(handles.menu_view_suggest_balanced,'Checked','off');
set(handles.menu_view_suggest_none,'Checked','off');
set(handles.guidata.htimeline_gt_suggestions,'Visible','on');
handles = UpdateTimelineIms(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);
  
  
% --------------------------------------------------------------------
function menu_view_suggest_threshold_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_suggest_threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

in = inputdlg({'Threshold for suggestion'});
if isempty(in) || ~ischar(in{1}) ,
  return;
end
threshold = str2double(in{1});
if isnan(threshold) || abs(threshold-0.5)>0.5  
  warndlg('Input value between 0 and 1');
  return;
end

handles.guidata.data.SuggestThresholdGT(threshold);

set(handles.menu_view_suggest_random,'Checked','off');
set(handles.menu_view_suggest_threshold,'Checked','on');
set(handles.menu_view_suggest_balanced,'Checked','off');
set(handles.menu_view_suggest_file,'Checked','off');
set(handles.menu_view_suggest_none,'Checked','off');
set(handles.guidata.htimeline_gt_suggestions,'Visible','on');
handles = UpdateTimelineIms(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);


% --------------------------------------------------------------------
function menu_view_suggest_none_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_suggest_none (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.menu_view_suggest_random,'Checked','off');
set(handles.menu_view_suggest_threshold,'Checked','off');
set(handles.menu_view_suggest_file,'Checked','off');
set(handles.menu_view_suggest_balanced,'Checked','off');
set(handles.menu_view_suggest_none,'Checked','on');
set(handles.guidata.htimeline_gt_suggestions,'Visible','off');

handles = UpdateTimelineIms(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);


% --------------------------------------------------------------------
function menu_view_suggest_balanced_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_suggest_balanced (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

avgBoutLen = handles.guidata.data.GetAvgPredictionBoutLen();

indlg1 = sprintf('Number of frames per labeling interval (Avg prediction bout length is %.2f)',avgBoutLen);
in = inputdlg({indlg1,'Number of intervals'});
if isempty(in), return; end
intsize = str2double(in{1});
numint = str2double(in{2});
if isnan(intsize) || (round(intsize)-intsize)~=0 || ...
    isnan(numint) || (round(numint)-numint)~=0 
  warndlg('Input error: enter integer values');
  return;
end

[success,msg ] = handles.guidata.data.SuggestBalancedGT(intsize,numint);
if ~success, warndlg(msg); return; end

set(handles.menu_view_suggest_random,'Checked','off');
set(handles.menu_view_suggest_threshold,'Checked','off');
set(handles.menu_view_suggest_file,'Checked','off');
set(handles.menu_view_suggest_balanced,'Checked','on');
set(handles.menu_view_suggest_none,'Checked','off');
set(handles.guidata.htimeline_gt_suggestions,'Visible','on');
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);



% --------------------------------------------------------------------
function menu_view_suggest_file_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_suggest_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename,pathname] = uigetfile('*.txt',...
  sprintf('Choose ground truth suggestion file config file for experiment %s',handles.guidata.data.expnames{handles.guidata.expi}) ,...
  handles.guidata.data.expdirs{handles.guidata.expi});
if ~filename, return, end;

handles.guidata.data.SuggestLoadedGT(handles.guidata.expi,fullfile(pathname,filename));

set(handles.menu_view_suggest_random,'Checked','off');
set(handles.menu_view_suggest_threshold,'Checked','off');
set(handles.menu_view_suggest_file,'Checked','on');
set(handles.menu_view_suggest_none,'Checked','off');
set(handles.guidata.htimeline_gt_suggestions,'Visible','on');
set(handles.menu_view_suggest_file,'Checked','off');
handles = UpdateTimelineIms(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);


% --------------------------------------------------------------------
function menu_classifier_gt_performance_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_gt_performance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
crossError = handles.guidata.data.GetGTPerformance();
cnames = {sprintf('%s|Predicted',handles.guidata.data.labelnames{1}),...
          'Not|Predicted',...
          sprintf('%s|Predicted',handles.guidata.data.labelnames{2}),...
          };
rnames = {sprintf('%s Important ',handles.guidata.data.labelnames{1}),...
          sprintf('%s ',handles.guidata.data.labelnames{1}),...
          sprintf('%s Important ',handles.guidata.data.labelnames{2}),...
          sprintf('%s ',handles.guidata.data.labelnames{2}),...
          };

dat = {};
for col = 1:3
  for row = 1:4
    t1 = sprintf('%d ',crossError.numbers(row,col));
    if isnan(crossError.frac(row,col))
      t2 = ' (-)';
    else
      t2 = sprintf(' (%.1f%%)',crossError.frac(row,col)*100);
    end
    dat{row,col} = sprintf('%s%s',t1,t2);
  end
end

        
f = figure('Position',[200 200 500 120],'Name','Ground Truth Performance');
t = uitable('Parent',f,'Data',dat,'ColumnName',cnames,... 
            'RowName',rnames,'Units','normalized','Position',[0 0 0.99 0.99]);


% --------------------------------------------------------------------
function menu_view_zoom_showwholevideo_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_zoom_showwholevideo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set to static view
menu_view_zoom_static_Callback(hObject, eventdata, handles);
ShowWholeVideo(handles);


% --------------------------------------------------------------------
function menu_file_package_labels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_package_labels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.guidata.data.expdirs),
  uiwait(warndlg('No label data to package'));
  return;
end

inlabelfilenames = {};
outlabelfilestrs = {};
labelfilestr = handles.guidata.data.GetFileName('label');
gtlabelfilestr = handles.guidata.data.GetFileName('gt_label');
for i = 1:handles.guidata.data.nexps,
  [~,expname] = myfileparts(handles.guidata.data.expdirs{i});
  inlabelfilename = handles.guidata.data.GetFile('label',i);
  if exist(inlabelfilename,'file')
    inlabelfilenames{end+1} = inlabelfilename; %#ok<AGROW>
    outlabelfilestrs{end+1} = sprintf('%s_%s',expname,labelfilestr); %#ok<AGROW>
  end
  inlabelfilename = handles.guidata.data.GetFile('gt_label',i);
  if exist(inlabelfilename,'file')
    inlabelfilenames{end+1} = inlabelfilename; %#ok<AGROW>
    outlabelfilestrs{end+1} = sprintf('%s_%s',expname,gtlabelfilestr); %#ok<AGROW>
  end
end

if isempty(inlabelfilenames),
  uiwait(warndlg('No label data to package'));
  return;
end

% choose an output directory
if ~isempty(handles.guidata.packageoutputdir),
  [outparentdir,packagename] = myfileparts(handles.guidata.packageoutputdir);
else
  if ~isempty(handles.guidata.expi) && handles.guidata.expi > 0,
    outparentdir = myfileparts(handles.guidata.data.expdirs{handles.guidata.expi});
  else
    outparentdir = myfileparts(handles.guidata.data.expdirs{1});
  end
  packagename = sprintf('LastName_FirstName_%s_%s',handles.guidata.configparams.behaviors.names,datestr(now,'yyyymmddTHHMMSS'));
end
outparentdir = uigetdir(outparentdir,'Choose parent directory to output label package to');
if ~ischar(outparentdir),
  return;
end
if ~exist(outparentdir,'dir'),
  try
    [success,msg] = mkdir(outparentdir);
    if ~success,
      error(msg);
    end
  catch ME,
    errordlg(sprintf('Error making directory %s: %s',outparentdir,getReport(ME)));
    return;
  end
end
options.Resize='on';
res = inputdlg({'Package name'},'Choose a name for the package directory',1,{packagename},options);
if isempty(res),
  return;
end
packagename = res{1};
outdir = fullfile(outparentdir,packagename);
if ~exist(outdir,'dir'),
  try
    [success,msg] = mkdir(outdir);
    if ~success,
      error(msg);
    end
  catch ME,
    errordlg(sprintf('Error making directory %s: %s',outdir,getReport(ME)));
    return;
  end
end

for i = 1:numel(inlabelfilenames),
  try
    [success,msg] = copyfile(inlabelfilenames{i},fullfile(outdir,outlabelfilestrs{i}));
    if ~success,
      error(msg);
    end
  catch ME,
    errordlg(sprintf('Error copying file %s to %s: %s',inlabelfilenames{i},fullfile(outdir,outlabelfilestrs{i})),getReport(ME));
  end
end
handles.guidata.packageoutputdir = outdir;

function DisableGUI(handles)

handles.guidata.henabled = findall(handles.figure_JLabel,'Enable','on');
handles.guidata.enabled = false;
set(handles.guidata.henabled,'Enable','off');

function ReEnableGUI(handles)

handles.guidata.enabled = true;
set(handles.guidata.henabled,'Enable','on');


% --------------------------------------------------------------------
function menu_file_save_suggestions_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_save_suggestions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
expi = handles.guidata.expi;
expdir = handles.guidata.data.expdirs{expi};
outfile = fullfile(expdir,'GTSuggestions.txt');
[fname,pname] = uiputfile('*.txt','Save Ground Truth Suggestions',outfile);
if isempty(fname), return; end;
outfile = fullfile(pname,fname);
handles.guidata.data.SaveSuggestionGT(expi,outfile);


% --------------------------------------------------------------------
function menu_edit_cache_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_cache (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curval = sprintf('%d',handles.guidata.data.cacheSize);
v = inputdlg('Memory usage (MB)','Cache Size',1,{curval});
sz = str2double(v{1});
if isnan(sz) || sz<0;
  return;
end

handles.guidata.cacheSize = round(sz);
handles.guidata.data.cacheSize = round(sz);


% --------------------------------------------------------------------
function menu_classifier_postprocess_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_postprocess (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

posthandle = PostProcess(handles.guidata.data,handles);
handles.guidata.open_peripherals(end+1) = posthandle;


% --------------------------------------------------------------------
function menu_classifier_classifyCurrentMovieSave_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classifyCurrentMovieSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.guidata.data.PredictSaveMovie(handles.guidata.expi);

% --------------------------------------------------------------------
function menu_classifier_classifyCurrentMovieSaveNew_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classifyCurrentMovieSaveNew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
expi = handles.guidata.expi;
fspec = fullfile(handles.guidata.data.expdirs{expi},'*.mat'); 
[fname,pname] = uiputfile(fspec);
if fname==0,
  return;
end
handles.guidata.data.PredictSaveMovie(handles.guidata.expi,fullfile(pname,fname));
handles = UpdateTimelineIms(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);


% --------------------------------------------------------------------
function menu_classifier_classifyCurrentMovieNoSave_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classifyCurrentMovieNoSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.guidata.data.PredictNoSaveMovie(handles.guidata.expi);
handles = UpdateTimelineIms(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);


% --------------------------------------------------------------------
function menu_file_savescores_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_savescores (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_file_savescores_default_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_savescores_default (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.guidata.data.SaveCurScores(handles.guidata.expi);

% --------------------------------------------------------------------
function menu_file_savescores_new_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_savescores_new (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
expi = handles.guidata.expi;
fspec = fullfile(handles.guidata.data.expdirs{expi},'*.mat'); 
[fname,pname] = uiputfile(fspec);
if fname==0,
  return;
end
handles.guidata.data.SaveCurScores(handles.guidata.expi,fullfile(pname,fname));


% --------------------------------------------------------------------
function menu_file_savescores_alldefault_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_savescores_alldefault (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
for ndx = 1:handles.guidata.data.nexps
  handles.guidata.data.SaveCurScores(ndx);
end


% --------------------------------------------------------------------
function menu_file_savescores_allnew_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_savescores_allnew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fname = inputdlg('Save the scores in the experiment directory to file.. ' );
if isempty(fname),
  return;
end
for ndx = 1:handles.guidata.data.nexps
  handles.guidata.data.SaveCurScores(ndx,fullfile(handles.guidata.data.expdirs{ndx},fname));
end


% --------------------------------------------------------------------
function menu_classifier_classifyall_default_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classifyall_default (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
for ndx = 1:handles.guidata.data.nexps,
  handles.guidata.data.PredictSaveMovie(ndx);
end

% --------------------------------------------------------------------
function menu_classifier_classifyall_new_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classifyall_new (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fname = inputdlg('Save scores to.. ' );
if isempty(fname),
  return;
end
for ndx = 1:handles.guidata.data.nexps
  handles.guidata.data.PredictSaveMovie(ndx,fullfile(handles.guidata.data.expdirs{ndx},fname));
end


% --------------------------------------------------------------------
function menu_classifier_classifyall_nosave_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classifyall_nosave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
for ndx = 1:handles.guidata.data.nexps
handles.guidata.data.PredictNoSaveMovie(ndx);
end


% --------------------------------------------------------------------
function menu_file_save_project_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_save_project (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.guidata.data.SaveProject();
set(handles.menu_file_save_project,'Enable','off');


% --------------------------------------------------------------------
function menu_help_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_help_about_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help_about (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
vid = fopen('version.txt','r');
vv = textscan(vid,'%s');
fclose(vid);
helpdlg(sprintf('JAABA (Janelia Automated Animal Behavior Annotator) version:%s',vv{1}{1}));

% --------------------------------------------------------------------
function menu_help_doc_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help_doc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isdeployed,
  %html_file = deployedRelative2Global('docs/index.html');
  html_file = 'http://jaaba.sourceforge.net/';
  [stat,msg] = myweb_nocheck(html_file);
  if stat ~= 0,
    errordlg({'Please see documentation at http://jaaba.sourceforge.net'
      'Error opening webpage within MATLAB:'
      msg});
  end
else
  web('-browser','http://jaaba.sourceforge.net/');
end


function menu_classifier_compareFrames_Callback(hObject,eventdata)
handles = guidata(hObject);
if isempty(handles.guidata.expi) || handles.guidata.expi<1, return, end
chandles = CompareFrames('JLabelH',handles,'expnum',handles.guidata.expi,...
  'fly',handles.guidata.flies,'t',handles.guidata.ts);
handles.guidata.open_peripherals(end+1) = chandles;
