# An example of how to do OpenID authenfication using Sinatra

require 'rubygems'
require 'sinatra'
gem 'ruby-openid', '>=2.1.2'
require 'openid'
require 'openid/store/filesystem'

helpers do
  def openid_consumer
    @openid_consumer ||= OpenID::Consumer.new(session,
        OpenID::Store::Filesystem.new("#{File.dirname(__FILE__)}/tmp/openid"))  
  end

  def root_url
    request.url.match(/(^.*\/{2}[^\/]*)/)[1]
  end
end


get '/login' do
  erb :login
end

post '/login/openid' do
  openid = params[:openid_identifier]
  begin
    response = openid_consumer.begin(openid)
  rescue OpenID::DiscoveryFailure => why
    "Sorry, we couldn't find your identifier #{openid}."
  else
    # You could request additional information here - see specs:
    # http://openid.net/specs/openid-simple-registration-extension-1_0.html
    # response.add_extension_arg('sreg','required','nickname')
    # response.add_extension_arg('sreg','optional','fullname, email')

    # Send request - first parameter: Trusted Site,
    # second parameter: redirect target
    redirect response.redirect_url(root_url, root_url + "/login/openid/complete")
  end
end

get '/login/openid/complete' do
  response = openid_consumer.complete(params, request.url)
  openid = response.display_identifier

  case response.status
    when OpenID::Consumer::FAILURE
      "Sorry, we could not authenticate you with this identifier #{openid}."

    when OpenID::Consumer::SETUP_NEEDED
      "Immediate request failed - Setup Needed"

    when OpenID::Consumer::CANCEL
      "Login cancelled."

    when OpenID::Consumer::SUCCESS
      # Access additional informations:
      # puts params['openid.sreg.nickname']
      # puts params['openid.sreg.fullname']

      "Login successfull."  # startup something
  end
end


use_in_file_templates!

__END__

@@ layout
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
       "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
  <title>got openid?</title>
</head>
<body>
  <%= yield %>
</body>
</html>


@@ login
<form method="post" accept-charset="UTF-8" action='/login/openid'>
  Identifier:
  <input type="text" class="openid" name="openid_identifier" />
  <input type="submit" value="Verify" />
</form>
