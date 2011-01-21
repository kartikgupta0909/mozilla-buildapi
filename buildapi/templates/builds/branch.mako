<%inherit file="/base.mako" />
<%def name="title()">Builds for ${c.branch}</%def>
<%def name="header()">
<script type="text/javascript">
function revurl(rev)
{
    return "${h.url('branch', branch=c.branch)}/rev/" + rev;
}

$(document).ready(function()
{
    var options = {
        "bJQueryUI": true,
        "sPaginationType": "full_numbers"
    }
    $("#builds").dataTable(options);
    $("#running").dataTable(options);
    $("#pending").dataTable(options);

    $("#revform").submit(function()
    {
        var rev = $("#revfield").val();
        $(location).attr('href', revurl(rev));
        return false;
    });
})

function toggle_display(id)
{
    var node = $(id);
    if (node.css('display') == 'none')
    {
        node.css('display', 'inline');
    }
    else
    {
        node.css('display', 'none');
    }
}
</script>
</%def>

<%def name="cancel_request_form(request_id)">
<form method="POST" action="${h.url('cancel_request', branch=c.branch, request_id=request_id)}">
<input type="hidden" name="_method" value="DELETE" />
<input type="submit" value="cancel" />
</form>
</%def>

<%def name="cancel_build_form(build_id)">
<form method="POST" action="${h.url('cancel_build', branch=c.branch, build_id=build_id)}">
<input type="hidden" name="_method" value="DELETE" />
<input type="submit" value="cancel" />
</form>
</%def>

<%def name="rebuild_form(build_id)">
<form method="POST" action="${h.url('rebuild_build', branch=c.branch)}">
<input type="hidden" name="_method" value="POST" />
<input type="hidden" name="build_id" value="${build_id}" />
<input type="submit" value="rebuild" />
</form>
</%def>

<%def name="priority_form(request_id, priority, label)">
<form method="POST" action="${h.url('reprioritize', branch=c.branch, request_id=request_id)}">
<input type="hidden" name="_method" value="PUT" />
<input type="hidden" name="priority" value="${priority}" />
<input type="submit" value="${label}" />
</form>
</%def>

<%!
import time

def formattime(t):
    if not t:
        return ""
    return time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(t))

statusText = {
    0: 'Success',
    1: 'Warnings',
    2: 'Failure',
    3: 'Skipped',
    4: 'Exception',
    5: 'Retry',
    }

def formatStatus(status):
    return statusText.get(status, '')
%>

<%def name="buildrow(build, tabletype)">
<tr class="result${build.get('status')}">
    <td>
    % if tabletype in ('running', 'pending'):
        % if build.get('build_id'):
            ${cancel_build_form(build['build_id'])}
        % elif build.get('request_id'):
            ${cancel_request_form(build['request_id'])}
        % endif
    % endif
    % if build.get('build_id'):
        ${rebuild_form(build['build_id'])}
    % endif
    </td>
    % if build.get('build_id'):
        <td><a href="${h.url('build', branch=c.branch, build_id=build.get('build_id'))}">${build['buildername']}</a></td>
    % elif build.get('request_id'):
        <td><a href="${h.url('request', branch=c.branch, request_id=build.get('request_id'))}">${build['buildername']}</a></td>
    % else:
        <td>${build['buildername']}</td>
    % endif
    <td>
    % if build.get('revision'):
        <a href="${h.url('revision', branch=c.branch, revision=build['revision'])}">${build['revision']}</a>
    % endif
    </td>
    % if tabletype == 'builds':
        <td>${formatStatus(build.get('status'))}</td>
    % endif
    % if tabletype == 'pending':
        <td>${formattime(build.get('submittime'))}</td>
        <td>${build.get('priority')}
            ${priority_form(build['request_id'], build.get('priority', 0)+1, '+1')}
            ${priority_form(build['request_id'], build.get('priority', 0)-1, '-1')}
        </td>
    % else:
        <td>${formattime(build.get('starttime'))}</td>
        <td>${formattime(build.get('endtime'))}</td>
    % endif
</tr>
</%def>

<%def name="breadcrumbs()">
<a href="${h.url('builds_home')}">BuildAPI Home</a><br/>
</%def>

<%def name="body()">
<form id="revform">
Look up builds by revision: <input id="revfield" type="text" name="revision">
</form>

% for tabletype in ('pending', 'running', 'builds'):
    <h1>${tabletype}</h1>
    <div>
    <table id="${tabletype}">
    <thead>
    <tr>
    % if tabletype == 'pending':
        <th></th><th>Builder</th><th>Revision</th><th>Submit time</th><th>Priority</th>
    % elif tabletype == 'running':
        <th></th><th>Builder</th><th>Revision</th><th>Start time</th><th>End time</th>
    % else:
        <th></th><th>Builder</th><th>Revision</th><th>Status</th><th>Start time</th><th>End time</th>
    % endif
    </tr>
    </thead>
    <tbody>
    % for build in c.data[tabletype]:
        ${buildrow(build, tabletype)}
    % endfor
    </tbody>
    </table>
    </div>
% endfor

<br/>
<a href='#' onclick="toggle_display('#raw')">Show raw data</a>
<br/>
<div id="raw" style="display:none">
Raw data:<br/>
${c.formatted_data|n}
</div>
</%def>