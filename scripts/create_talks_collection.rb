require 'json'
require 'fileutils'
require 'yaml'

class CreateTalksCollection
  JSON_FOLDER = '../src/_data/youtube_playlists'
  TALKS_FOLDER = "../src/_talks"
  PEOPLE_FOLDER = "../src/_people"
  IMAGES_FOLDER = "../src/uploads"

  def initialize
    people_paths = Dir["#{PEOPLE_FOLDER}/*"] - ["#{PEOPLE_FOLDER}/_defaults.md"]
    @people_hashes = people_paths.map { |p| YAML.load_file(p) }
    @yt_json = JSON.parse(IO.read(json_path))
  end

  def call
    people_hashes.each do |person|
      next if person["youtube_video_id"].nil?
      next if yt_json[person["youtube_video_id"]].nil?
      video = yt_json[person["youtube_video_id"]]
      puts person["name"]
      puts video["title"]

      person["youtube_video_ids"] = [person["youtube_video_id"]]
      talk_hash = talk_schema(video, person)
      person.delete("youtube_video_id")
      write_md_file("#{TALKS_FOLDER}/#{talk_filename(video)}", talk_hash)
    end
  end

  private

  attr_reader :people_hashes, :yt_json

  def talk_schema(video, person)
    {
      "title" => talk_title(video),
      "presenter" => person["name"],
      "images" => talk_images(person["name"].downcase.gsub(" ", "-")),
      "youtube_video_id" => person["youtube_video_id"],
      "tags" => video["tags"]
    }
  end

  def talk_images(name)
    Dir["#{IMAGES_FOLDER}/#{name}_talk*"].map do |path|
      path.gsub(IMAGES_FOLDER, "")
    end
  end

  def talk_title(video)
    video["title"]
      .yield_self { |title| title.split("|").first}
      .yield_self { |title| title.split(":").first}
      .yield_self { |title| title.strip }
  end

  def talk_filename(video)
    talk_title(video)
      .yield_self { |title| title.gsub("/", "|") }
      .yield_self { |title| title.gsub(" ", "-") }
      .yield_self { |title| title.downcase }
      .yield_self { |title| "#{title}.md" }
  end

  def write_md_file(path, data)
    File.open(path, 'w') do |f|
      f << data.to_yaml
      f << "---\n"
    end
  end

  def json_path
    File.expand_path("#{JSON_FOLDER}/videos.json")
  end
end

CreateTalksCollection.new.call
