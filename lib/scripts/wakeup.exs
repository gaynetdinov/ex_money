:application.start(:inets)
:ssl.start
url = 'https://#{System.get_env("HOME_URL")}'
:httpc.request(:get, {url, []}, [{:timeout, :timer.seconds(30)}], [])
:ssl.stop
:application.stop(:inets)
