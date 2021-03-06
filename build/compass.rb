require 'rubygems'
require 'bundler/setup'
#require 'json' todo remove
require 'yaml'
require 'erb'
require 'ostruct'
require 'fileutils'
require 'compass/import-once/activate'
require 'sass-css-importer' #gem install --pre sass-css-importer
require 'sass-globbing'
require 'rgbapng'
require 'breakpoint'
require 'jacket'
#require 'bootstrap-sass'


#environment = :development --> this is default!
#environment = :production

if File.exists?(File.join(File.dirname(__FILE__), 'grunt-config', 'paths.yml'))
	paths = YAML::load_file(File.join(File.dirname(__FILE__), 'grunt-config', 'paths.yml'))
else
  paths = {
    'sass' => 'application/assets/stylesheets',
    'www' => 'www',
    'css' => '<%= www %>/stylesheets',
    'images' => '<%= www %>/images',
    'fonts' => '<%= www %>/fonts',
    'vendor' => '<%= www %>/vendor',
    'tmp' => 'var/tmp'
  }
end
paths_namespace = OpenStruct.new paths
paths.each do |k,v|
  path_parsed = ERB.new(v.gsub('paths.', '')).result(paths_namespace.instance_eval { binding })
  paths_namespace.send(k +"=", path_parsed)
end

#custom variables
project_path = File.expand_path(File.join(File.dirname(__FILE__), '..'))

sass_dir = paths_namespace.sass
# this setting enforces the compilation of `style.css` in the theme root folder
css_dir = paths_namespace.css
images_dir = paths_namespace.images

#Place a common cache folder in the project path
cache_path = File.expand_path(File.join(project_path, paths_namespace.tmp, '.sass-cache'))

#http_stylesheets_path = project_url
http_images_path = paths_namespace.images.gsub(paths_namespace.www, '')
http_generated_images_path =  paths_namespace.images.gsub(paths_namespace.www, '')

#path of font folder
fonts_dir =  paths_namespace.fonts
#enforce this setting
fonts_path =  File.join(project_path, fonts_dir)
http_fonts_path = paths_namespace.fonts.gsub(paths_namespace.www, '')


if environment == :production
	asset_cache_buster :none
	output_style = :expanded #there's an external task to minify css
end

#sourcemaps support
if environment != :production
  sourcemap = true
end

#import sass vendors
add_import_path File.expand_path(File.join(project_path, paths_namespace.vendor))
#import plain css
add_import_path Sass::CssImporter::Importer.new(File.join(project_path, paths_namespace.vendor))

# use this hook when `css_path` is different from `project_path`
# to move style.css to the theme root
# on_stylesheet_saved do |file|
#   if File.exists?(file) && File.basename(file) == "style.css"
#     puts "Moving: #{file}"
#     FileUtils.mv(file, project_path + "/" + File.basename(file))
#   end
# end

Sass::Script::Number.precision = 10


#plugins
# https://gist.github.com/4151748
# http://stackoverflow.com/questions/10314907/getting-a-list-of-files-in-sass-compass
module Sass::Script::Functions
  def list_files(path)

  	full_path = File.join(Compass.configuration.project_path, path.value)
    return Sass::Script::List.new(
      Dir.glob(full_path).map! { |x| Sass::Script::String.new(File.basename(x, '.*')) },
      :comma
    )
  end
end

module Sass::Script::Functions
  def list_images(relpath)

    if Compass.configuration.images_path
      full_path = File.join(Compass.configuration.images_path, relpath.value)
    else
      full_path = File.join(Compass.configuration.project_path, relpath.value)
    end
    return Sass::Script::List.new(
      Dir.glob(full_path).map! { |x| Sass::Script::String.new(File.basename(x, '.*')) },
      :comma
    )
  end
end

###
#
# Retina helper mixins for Compass
# http://www.joelambert.co.uk
#
# Copyright 2012, Joe Lambert.
# Free to use under the MIT license.
# http://joelambert.mit-license.org/
#
# https://github.com/joelambert/Retina-Compass-Helpers
#
###
module Compass::SassExtensions::Functions::Files
  # Does the supplied image exists?
  def file_exists(image_file)
    path = image_file.value
    # Compute the real path to the image on the file system if the images_dir is set.
    if Compass.configuration.images_path
      path = File.join(Compass.configuration.images_path, path)
    else
      path = File.join(Compass.configuration.project_path, path)
    end

    Sass::Script::Bool.new(File.exists?(path))
  end

  # Generate a filename with @2x appended to the end
  def retina_filename(image_file)
    filename = image_file.value
    parts = filename.split('.')
    ext = parts.pop
    f = parts.pop
    f = f + "@2x"
    parts.push(f)
    parts.push(ext)
    Sass::Script::String.new(parts.join('.'))
  end
end

module Sass::Script::Functions
  include Compass::SassExtensions::Functions::Files
end

#Copy fonts file from gem bootstrap-sass to specified fonts folder
on_stylesheet_saved do |file|
	if defined?(::Bootstrap)
		Dir.glob(Bootstrap.fonts_path + '/bootstrap/*').each do |file|
			font_file_base = File.basename(file)
			bootstrap_font_dir = File.join(project_path, fonts_path, 'bootstrap')

			#generate boostrapdir
			unless File.directory?(bootstrap_font_dir)
				FileUtils.mkdir_p(bootstrap_font_dir)
			end

			unless File.exists?(File.join(bootstrap_font_dir, font_file_base))
				FileUtils.copy_file(file, bootstrap_font_dir + '/' + font_file_base)
			end
		end
	end
end

