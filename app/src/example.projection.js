fromStream('example-stream')
  .when({
    message: function (state, event) {
      return Object.assign(state, event, { lastModified: Date.now() })
    }
  })
