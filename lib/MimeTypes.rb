require "./Lib/MimeTypesDB.rb"
class MimeTypes
    def initialize
    end
    def lookUp(name)
        name=name.split(".")
        name=name[name.length-1].strip()
        return MimeTypesDB::TYPES[:"#{name}"]||"application/octet-stream"
    end
end