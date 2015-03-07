if Meteor.isServer
  Meteor.startup ->

    describe 'A Restivus API', ->
      context 'that hasn\'t been configured', ->
        it 'should have default settings', (test) ->
          test.equal Restivus.config.apiPath, 'api/'
          test.isFalse Restivus.config.useAuth
          test.isFalse Restivus.config.prettyJson
          test.equal Restivus.config.auth.token, 'services.resume.loginTokens.token'

        it 'should allow you to add an unconfigured route', (test) ->
          Restivus.addRoute 'test1', {authRequired: true, roleRequired: 'admin'},
            get: ->
              1

          route = Restivus.routes[0]
          test.equal route.path, 'test1'
          test.equal route.endpoints.get(), 1
          test.isTrue route.options.authRequired
          test.equal route.options.roleRequired, 'admin'
          test.isUndefined route.endpoints.get.authRequired
          test.isUndefined route.endpoints.get.roleRequired

        it 'should allow you to add an unconfigured collection route', (test) ->
          Restivus.addCollection new Mongo.Collection('tests'),
            routeOptions:
              authRequired: true
              roleRequired: 'admin'
            endpoints:
              getAll:
                action: ->
                  2

          route = Restivus.routes[1]
          test.equal route.path, 'tests'
          test.equal route.endpoints.get.action(), 2
          test.isTrue route.options.authRequired
          test.equal route.options.roleRequired, 'admin'
          test.isUndefined route.endpoints.get.authRequired
          test.isUndefined route.endpoints.get.roleRequired

        it 'should be configurable', (test) ->
          Restivus.configure
            apiPath: 'api/v1'
            useAuth: true
            auth: token: 'apiKey'

          config = Restivus.config
          test.equal config.apiPath, 'api/v1/'
          test.equal config.useAuth, true
          test.equal config.auth.token, 'apiKey'

      context 'that has been configured', ->
        it 'should not allow reconfiguration', (test) ->
          test.throws Restivus.configure, 'Restivus.configure() can only be called once'

        it 'should configure any previously added routes', (test) ->
          route = Restivus.routes[0]
          test.equal route.endpoints.get.action(), 1
          test.isTrue route.endpoints.get.authRequired
          test.equal route.endpoints.get.roleRequired, ['admin']

        it 'should configure any previously added collection routes', (test) ->
          route = Restivus.routes[1]
          test.equal route.endpoints.get.action(), 2
          test.isTrue route.endpoints.get.authRequired
          test.equal route.endpoints.get.roleRequired, ['admin']

    describe 'A collection route', ->
      it 'should be able to exclude endpoints using just the excludedEndpoints option', (test, next) ->
        Restivus.addCollection new Mongo.Collection('tests2'),
          excludedEndpoints: ['get', 'getAll']
#          endpoints:
#            post: false


        HTTP.get 'http://localhost:3000/api/v1/tests2/10', (error, result) ->
          response = JSON.parse result.content
          test.isTrue error
          test.equal result.statusCode, 404
          test.equal response.status, 'error'
          test.equal response.message, 'API endpoint not found'

        HTTP.get 'http://localhost:3000/api/v1/tests2/', (error, result) ->
          response = JSON.parse result.content
          test.isTrue error
          test.equal result.statusCode, 404
          test.equal response.status, 'error'
          test.equal response.message, 'API endpoint not found'
          next()

    describe 'An endpoint', ->
      it 'should have access to multiple query params', (test, next) ->
        Restivus.addRoute 'mult-query-params',
          get: ->
            test.equal @queryParams.key1, '1234'
            test.equal @queryParams.key2, 'abcd'
            test.equal @queryParams.key3, 'a1b2'
            true


        HTTP.get 'http://localhost:3000/api/v1/mult-query-params?key1=1234&key2=abcd&key3=a1b2', (error, result) ->
          test.isTrue result
          next()

    describe 'A collection endpoint', ->
      it 'should have access to multiple query params', (test, next) ->
        Restivus.addCollection new Mongo.Collection('TestQueryParams'),
          path: 'mult-query-params-2'
          endpoints:
            getAll:
              action: ->
                test.equal @queryParams.key1, '1234'
                test.equal @queryParams.key2, 'abcd'
                test.equal @queryParams.key3, 'a1b2'
                true


        HTTP.get 'http://localhost:3000/api/v1/mult-query-params-2?key1=1234&key2=abcd&key3=a1b2', (error, result) ->
          test.isTrue result
          next()

#      context 'that has been authenticated', ->
#        it 'should have access to this.user and this.userId', (test) ->




#Tinytest.add 'A route - should be configurable', (test)->
#  Restivus.configure
#    apiPath: '/api/v1'
#    prettyJson: true
#    auth:
#      token: 'apiKey'
#
#  test.equal Restivus.config.apiPath, '/api/v1'
