# Converts less files to css
#
# Uses the following properties in _config.yaml
# => lessc: path of less compiler, can be ommitted if less if included in the sys env path
# => css_dest: directory where all css output will write to
#
# Notes
# => css files will have the same root name as their less counterparts


module Jekyll

  # Expects a lessc: key in your _config.yml file with the path to a local less.js/bin/lessc
  # Less.js will require node.js to be installed
  class LessJsGenerator < Generator
    safe true
    priority :low

    def generate(site)
      # location of less compiler
      lessc = site.config['lessc'] || "lessc"
      raise "Missing 'lessc' path in site configuration" if(!lessc)

      # css destination
      css_dest = site.config['css_dest'] || "/"

      less_files = Array.new

      # static_files have already been filtered against excludes, etc.
      site.static_files.delete_if do |sf|
        next if not File.extname(sf.path) == ".less"

        less_dir = File.dirname(sf.path.gsub(site.source, ""))
        less_name = File.basename(sf.path)

        # add out less file
        less_files << LessCssFile.new(site, site.source, less_dir, less_name, css_dest, lessc)

        # return true so less file gets removed
        # and not copied to _site output
        true
      end

      # concat new less pages with site static files
      site.static_files.concat(less_files)
    end

  end


  class LessCssFile < StaticFile
    def initialize(site, base, dir, name, cssroot, lessc)
      super(site, base, dir, name, nil)

      @lesspath = File.join(base, dir, name)
      @cssdir = cssroot
      @lessc = lessc
    end

    def write(dest)
      # css name
      less_ext = /\.less$/i
      css_name = @name.gsub(less_ext, ".css")

      # css full path
      css_path = File.join(dest, @cssdir)
      css = File.join(css_path, css_name)

      # make sure dir exists
      FileUtils.mkdir_p(css_path)

      # execute shell command
      begin
        command = "#{@lessc} #{@lesspath} #{css}"

        `#{command}`
      end
    end
  end

end