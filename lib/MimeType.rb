require "./Lib/MimeTypeDB.rb"
class MimeType
    def initialize
    end
    def lookUp(name)
        name=name.split(".")
        name=name[name.length-1].strip()
        return MimeTypeDB[:types][:"#{name}"]||"application/octet-stream"
    end
end