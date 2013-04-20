<h1>Top 10 words, ranked by count</h1>
<ul>
%for item in toplist:
  <li>{{item['count']}} - <a href="https://www.google.com/search?q={{item['name']}}">{{item['name']}}</a></li>
%end
</ul>
%rebase layout title='top 10 list'
