module DynamicLinks
  class BaseCacheStore
    def write(key, value, options = {})
      raise NotImplementedError
    end

    def read(key)
      raise NotImplementedError
    end

    def delete(key)
      raise NotImplementedError
    end
  end
end
