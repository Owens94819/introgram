class Array
    def popIndex(index)
        if(index<1)
            return shift()
        elsif(index>(length-1))
            return pop()
        end
        index= length-index
        arr1= pop(index)
        val=arr1.shift()
         concat(arr1)
         return val
    end
end

def log(msg)
    puts("\n")
    puts(msg)
    puts("\n")
end