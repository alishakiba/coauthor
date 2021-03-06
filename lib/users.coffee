@findUser = (userId) ->
  if userId?
    Meteor.users.findOne(userId) ? {}
  else
    {}

@findUsername = (username) ->
  return username if username.username?
  Meteor.users.findOne
    username: username

@displayUser = (username) ->
  user = findUsername username
  user?.profile?.fullname?.trim?() or user?.username or username

@linkToAuthor = (group, user, title, prefix) ->
  username = user.username ? user
  title = "User '#{username}'" unless title?
  link = urlFor 'author',
    group: group
    author: username
  link = """<a class="author" data-username="#{username}" href="#{link}" title="#{title.replace /"/g, '&#34;'}" data-toggle="tooltip">#{prefix or ''}#{displayUser user}</a>"""
  if Meteor.isClient and
     Router.current()?.route?.getName() == 'author' and
     Router.current()?.params?.author == username
    link = """<span class="highlight">#{link}</span>"""
  link

## Sort by last name if available
@userSortKey = (username) ->
  display = displayUser username
  space = display.lastIndexOf ' '
  if space >= 0
    display[space+1..] + ", " + display[...space]
  else
    display

@validUsername = (username) ->
  validKey(username) and not username.match /[\s@]/

## Need to escape dots in usernames.
@escapeUser = escapeKey
@unescapeUser = unescapeKey

if Meteor.isServer
  Meteor.publish 'users', (group) ->
    @autorun ->
      user = findUser @userId
      ## User can see the list of all users of the Coauthor instance
      ## if they have been given admin privileges for the group or
      ## at least one thread in the group.
      if (groupRoleCheck group, 'admin', user) or
         (groupPartialMessagesWithRole group, 'admin', user).length > 0
        Meteor.users.find {}
        , fields:
            services: false
      else
        @ready()

  Meteor.publish 'userData', ->
    @autorun ->
      if @userId
        Meteor.users.find
          _id: @userId
        , fields:
            createdAt: true
            roles: true
            rolesPartial: true
            'services.dropbox.id': true
      else
        @ready()
else  ## client
  Meteor.subscribe 'userData'

Meteor.methods
  userEditEmail: (email) ->
    check Meteor.userId(), String
    if Meteor.isServer  ## no Accounts on client
      if Meteor.user().emails?[0]?.address?
        Accounts.removeEmail Meteor.userId(), Meteor.user().emails[0].address
      Accounts.addEmail Meteor.userId(), email
