
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS CodeCommit
## version: 2015-04-13
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS CodeCommit</fullname> <p>This is the <i>AWS CodeCommit API Reference</i>. This reference provides descriptions of the operations and data types for AWS CodeCommit API along with usage examples.</p> <p>You can use the AWS CodeCommit API to work with the following objects:</p> <p>Repositories, by calling the following:</p> <ul> <li> <p> <a>BatchGetRepositories</a>, which returns information about one or more repositories associated with your AWS account.</p> </li> <li> <p> <a>CreateRepository</a>, which creates an AWS CodeCommit repository.</p> </li> <li> <p> <a>DeleteRepository</a>, which deletes an AWS CodeCommit repository.</p> </li> <li> <p> <a>GetRepository</a>, which returns information about a specified repository.</p> </li> <li> <p> <a>ListRepositories</a>, which lists all AWS CodeCommit repositories associated with your AWS account.</p> </li> <li> <p> <a>UpdateRepositoryDescription</a>, which sets or updates the description of the repository.</p> </li> <li> <p> <a>UpdateRepositoryName</a>, which changes the name of the repository. If you change the name of a repository, no other users of that repository will be able to access it until you send them the new HTTPS or SSH URL to use.</p> </li> </ul> <p>Branches, by calling the following:</p> <ul> <li> <p> <a>CreateBranch</a>, which creates a new branch in a specified repository.</p> </li> <li> <p> <a>DeleteBranch</a>, which deletes the specified branch in a repository unless it is the default branch.</p> </li> <li> <p> <a>GetBranch</a>, which returns information about a specified branch.</p> </li> <li> <p> <a>ListBranches</a>, which lists all branches for a specified repository.</p> </li> <li> <p> <a>UpdateDefaultBranch</a>, which changes the default branch for a repository.</p> </li> </ul> <p>Files, by calling the following:</p> <ul> <li> <p> <a>DeleteFile</a>, which deletes the content of a specified file from a specified branch.</p> </li> <li> <p> <a>GetBlob</a>, which returns the base-64 encoded content of an individual Git blob object within a repository.</p> </li> <li> <p> <a>GetFile</a>, which returns the base-64 encoded content of a specified file.</p> </li> <li> <p> <a>GetFolder</a>, which returns the contents of a specified folder or directory.</p> </li> <li> <p> <a>PutFile</a>, which adds or modifies a single file in a specified repository and branch.</p> </li> </ul> <p>Commits, by calling the following:</p> <ul> <li> <p> <a>BatchGetCommits</a>, which returns information about one or more commits in a repository</p> </li> <li> <p> <a>CreateCommit</a>, which creates a commit for changes to a repository.</p> </li> <li> <p> <a>GetCommit</a>, which returns information about a commit, including commit messages and author and committer information.</p> </li> <li> <p> <a>GetDifferences</a>, which returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID or other fully qualified reference).</p> </li> </ul> <p>Merges, by calling the following:</p> <ul> <li> <p> <a>BatchDescribeMergeConflicts</a>, which returns information about conflicts in a merge between commits in a repository.</p> </li> <li> <p> <a>CreateUnreferencedMergeCommit</a>, which creates an unreferenced commit between two branches or commits for the purpose of comparing them and identifying any potential conflicts.</p> </li> <li> <p> <a>DescribeMergeConflicts</a>, which returns information about merge conflicts between the base, source, and destination versions of a file in a potential merge.</p> </li> <li> <p> <a>GetMergeCommit</a>, which returns information about the merge between a source and destination commit. </p> </li> <li> <p> <a>GetMergeConflicts</a>, which returns information about merge conflicts between the source and destination branch in a pull request.</p> </li> <li> <p> <a>GetMergeOptions</a>, which returns information about the available merge options between two branches or commit specifiers.</p> </li> <li> <p> <a>MergeBranchesByFastForward</a>, which merges two branches using the fast-forward merge option.</p> </li> <li> <p> <a>MergeBranchesBySquash</a>, which merges two branches using the squash merge option.</p> </li> <li> <p> <a>MergeBranchesByThreeWay</a>, which merges two branches using the three-way merge option.</p> </li> </ul> <p>Pull requests, by calling the following:</p> <ul> <li> <p> <a>CreatePullRequest</a>, which creates a pull request in a specified repository.</p> </li> <li> <p> <a>DescribePullRequestEvents</a>, which returns information about one or more pull request events.</p> </li> <li> <p> <a>GetCommentsForPullRequest</a>, which returns information about comments on a specified pull request.</p> </li> <li> <p> <a>GetPullRequest</a>, which returns information about a specified pull request.</p> </li> <li> <p> <a>ListPullRequests</a>, which lists all pull requests for a repository.</p> </li> <li> <p> <a>MergePullRequestByFastForward</a>, which merges the source destination branch of a pull request into the specified destination branch for that pull request using the fast-forward merge option.</p> </li> <li> <p> <a>MergePullRequestBySquash</a>, which merges the source destination branch of a pull request into the specified destination branch for that pull request using the squash merge option.</p> </li> <li> <p> <a>MergePullRequestByThreeWay</a>. which merges the source destination branch of a pull request into the specified destination branch for that pull request using the three-way merge option.</p> </li> <li> <p> <a>PostCommentForPullRequest</a>, which posts a comment to a pull request at the specified line, file, or request.</p> </li> <li> <p> <a>UpdatePullRequestDescription</a>, which updates the description of a pull request.</p> </li> <li> <p> <a>UpdatePullRequestStatus</a>, which updates the status of a pull request.</p> </li> <li> <p> <a>UpdatePullRequestTitle</a>, which updates the title of a pull request.</p> </li> </ul> <p>Comments in a repository, by calling the following:</p> <ul> <li> <p> <a>DeleteCommentContent</a>, which deletes the content of a comment on a commit in a repository.</p> </li> <li> <p> <a>GetComment</a>, which returns information about a comment on a commit.</p> </li> <li> <p> <a>GetCommentsForComparedCommit</a>, which returns information about comments on the comparison between two commit specifiers in a repository.</p> </li> <li> <p> <a>PostCommentForComparedCommit</a>, which creates a comment on the comparison between two commit specifiers in a repository.</p> </li> <li> <p> <a>PostCommentReply</a>, which creates a reply to a comment.</p> </li> <li> <p> <a>UpdateComment</a>, which updates the content of a comment on a commit in a repository.</p> </li> </ul> <p>Tags used to tag resources in AWS CodeCommit (not Git tags), by calling the following:</p> <ul> <li> <p> <a>ListTagsForResource</a>, which gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit.</p> </li> <li> <p> <a>TagResource</a>, which adds or updates tags for a resource in AWS CodeCommit.</p> </li> <li> <p> <a>UntagResource</a>, which removes tags for a resource in AWS CodeCommit.</p> </li> </ul> <p>Triggers, by calling the following:</p> <ul> <li> <p> <a>GetRepositoryTriggers</a>, which returns information about triggers configured for a repository.</p> </li> <li> <p> <a>PutRepositoryTriggers</a>, which replaces all triggers for a repository and can be used to create or delete triggers.</p> </li> <li> <p> <a>TestRepositoryTriggers</a>, which tests the functionality of a repository trigger by sending data to the trigger target.</p> </li> </ul> <p>For information about how to use AWS CodeCommit, see the <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit User Guide</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/codecommit/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "codecommit.ap-northeast-1.amazonaws.com", "ap-southeast-1": "codecommit.ap-southeast-1.amazonaws.com",
                           "us-west-2": "codecommit.us-west-2.amazonaws.com",
                           "eu-west-2": "codecommit.eu-west-2.amazonaws.com", "ap-northeast-3": "codecommit.ap-northeast-3.amazonaws.com", "eu-central-1": "codecommit.eu-central-1.amazonaws.com",
                           "us-east-2": "codecommit.us-east-2.amazonaws.com",
                           "us-east-1": "codecommit.us-east-1.amazonaws.com", "cn-northwest-1": "codecommit.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "codecommit.ap-south-1.amazonaws.com",
                           "eu-north-1": "codecommit.eu-north-1.amazonaws.com", "ap-northeast-2": "codecommit.ap-northeast-2.amazonaws.com",
                           "us-west-1": "codecommit.us-west-1.amazonaws.com", "us-gov-east-1": "codecommit.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "codecommit.eu-west-3.amazonaws.com", "cn-north-1": "codecommit.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "codecommit.sa-east-1.amazonaws.com",
                           "eu-west-1": "codecommit.eu-west-1.amazonaws.com", "us-gov-west-1": "codecommit.us-gov-west-1.amazonaws.com", "ap-southeast-2": "codecommit.ap-southeast-2.amazonaws.com", "ca-central-1": "codecommit.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "codecommit.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "codecommit.ap-southeast-1.amazonaws.com",
      "us-west-2": "codecommit.us-west-2.amazonaws.com",
      "eu-west-2": "codecommit.eu-west-2.amazonaws.com",
      "ap-northeast-3": "codecommit.ap-northeast-3.amazonaws.com",
      "eu-central-1": "codecommit.eu-central-1.amazonaws.com",
      "us-east-2": "codecommit.us-east-2.amazonaws.com",
      "us-east-1": "codecommit.us-east-1.amazonaws.com",
      "cn-northwest-1": "codecommit.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "codecommit.ap-south-1.amazonaws.com",
      "eu-north-1": "codecommit.eu-north-1.amazonaws.com",
      "ap-northeast-2": "codecommit.ap-northeast-2.amazonaws.com",
      "us-west-1": "codecommit.us-west-1.amazonaws.com",
      "us-gov-east-1": "codecommit.us-gov-east-1.amazonaws.com",
      "eu-west-3": "codecommit.eu-west-3.amazonaws.com",
      "cn-north-1": "codecommit.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "codecommit.sa-east-1.amazonaws.com",
      "eu-west-1": "codecommit.eu-west-1.amazonaws.com",
      "us-gov-west-1": "codecommit.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "codecommit.ap-southeast-2.amazonaws.com",
      "ca-central-1": "codecommit.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "codecommit"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchDescribeMergeConflicts_593774 = ref object of OpenApiRestCall_593437
proc url_BatchDescribeMergeConflicts_593776(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDescribeMergeConflicts_593775(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_593888 = header.getOrDefault("X-Amz-Date")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Date", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Security-Token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Security-Token", valid_593889
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593903 = header.getOrDefault("X-Amz-Target")
  valid_593903 = validateParameter(valid_593903, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchDescribeMergeConflicts"))
  if valid_593903 != nil:
    section.add "X-Amz-Target", valid_593903
  var valid_593904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Content-Sha256", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Algorithm")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Algorithm", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Signature")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Signature", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-SignedHeaders", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Credential")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Credential", valid_593908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593932: Call_BatchDescribeMergeConflicts_593774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy.
  ## 
  let valid = call_593932.validator(path, query, header, formData, body)
  let scheme = call_593932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593932.url(scheme.get, call_593932.host, call_593932.base,
                         call_593932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593932, url, valid)

proc call*(call_594003: Call_BatchDescribeMergeConflicts_593774; body: JsonNode): Recallable =
  ## batchDescribeMergeConflicts
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy.
  ##   body: JObject (required)
  var body_594004 = newJObject()
  if body != nil:
    body_594004 = body
  result = call_594003.call(nil, nil, nil, nil, body_594004)

var batchDescribeMergeConflicts* = Call_BatchDescribeMergeConflicts_593774(
    name: "batchDescribeMergeConflicts", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchDescribeMergeConflicts",
    validator: validate_BatchDescribeMergeConflicts_593775, base: "/",
    url: url_BatchDescribeMergeConflicts_593776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetCommits_594043 = ref object of OpenApiRestCall_593437
proc url_BatchGetCommits_594045(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetCommits_594044(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns information about the contents of one or more commits in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594046 = header.getOrDefault("X-Amz-Date")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Date", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Security-Token")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Security-Token", valid_594047
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594048 = header.getOrDefault("X-Amz-Target")
  valid_594048 = validateParameter(valid_594048, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchGetCommits"))
  if valid_594048 != nil:
    section.add "X-Amz-Target", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Content-Sha256", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Signature")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Signature", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-SignedHeaders", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Credential")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Credential", valid_594053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594055: Call_BatchGetCommits_594043; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the contents of one or more commits in a repository.
  ## 
  let valid = call_594055.validator(path, query, header, formData, body)
  let scheme = call_594055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594055.url(scheme.get, call_594055.host, call_594055.base,
                         call_594055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594055, url, valid)

proc call*(call_594056: Call_BatchGetCommits_594043; body: JsonNode): Recallable =
  ## batchGetCommits
  ## Returns information about the contents of one or more commits in a repository.
  ##   body: JObject (required)
  var body_594057 = newJObject()
  if body != nil:
    body_594057 = body
  result = call_594056.call(nil, nil, nil, nil, body_594057)

var batchGetCommits* = Call_BatchGetCommits_594043(name: "batchGetCommits",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchGetCommits",
    validator: validate_BatchGetCommits_594044, base: "/", url: url_BatchGetCommits_594045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetRepositories_594058 = ref object of OpenApiRestCall_593437
proc url_BatchGetRepositories_594060(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetRepositories_594059(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about one or more repositories.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594061 = header.getOrDefault("X-Amz-Date")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Date", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Security-Token")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Security-Token", valid_594062
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594063 = header.getOrDefault("X-Amz-Target")
  valid_594063 = validateParameter(valid_594063, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchGetRepositories"))
  if valid_594063 != nil:
    section.add "X-Amz-Target", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Content-Sha256", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Algorithm")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Algorithm", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Signature")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Signature", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-SignedHeaders", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Credential")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Credential", valid_594068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594070: Call_BatchGetRepositories_594058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about one or more repositories.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ## 
  let valid = call_594070.validator(path, query, header, formData, body)
  let scheme = call_594070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594070.url(scheme.get, call_594070.host, call_594070.base,
                         call_594070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594070, url, valid)

proc call*(call_594071: Call_BatchGetRepositories_594058; body: JsonNode): Recallable =
  ## batchGetRepositories
  ## <p>Returns information about one or more repositories.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ##   body: JObject (required)
  var body_594072 = newJObject()
  if body != nil:
    body_594072 = body
  result = call_594071.call(nil, nil, nil, nil, body_594072)

var batchGetRepositories* = Call_BatchGetRepositories_594058(
    name: "batchGetRepositories", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchGetRepositories",
    validator: validate_BatchGetRepositories_594059, base: "/",
    url: url_BatchGetRepositories_594060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBranch_594073 = ref object of OpenApiRestCall_593437
proc url_CreateBranch_594075(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateBranch_594074(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new branch in a repository and points the branch to a commit.</p> <note> <p>Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594076 = header.getOrDefault("X-Amz-Date")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Date", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Security-Token")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Security-Token", valid_594077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594078 = header.getOrDefault("X-Amz-Target")
  valid_594078 = validateParameter(valid_594078, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateBranch"))
  if valid_594078 != nil:
    section.add "X-Amz-Target", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Content-Sha256", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Algorithm")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Algorithm", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Signature")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Signature", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-SignedHeaders", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Credential")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Credential", valid_594083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594085: Call_CreateBranch_594073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new branch in a repository and points the branch to a commit.</p> <note> <p>Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.</p> </note>
  ## 
  let valid = call_594085.validator(path, query, header, formData, body)
  let scheme = call_594085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594085.url(scheme.get, call_594085.host, call_594085.base,
                         call_594085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594085, url, valid)

proc call*(call_594086: Call_CreateBranch_594073; body: JsonNode): Recallable =
  ## createBranch
  ## <p>Creates a new branch in a repository and points the branch to a commit.</p> <note> <p>Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.</p> </note>
  ##   body: JObject (required)
  var body_594087 = newJObject()
  if body != nil:
    body_594087 = body
  result = call_594086.call(nil, nil, nil, nil, body_594087)

var createBranch* = Call_CreateBranch_594073(name: "createBranch",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateBranch",
    validator: validate_CreateBranch_594074, base: "/", url: url_CreateBranch_594075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCommit_594088 = ref object of OpenApiRestCall_593437
proc url_CreateCommit_594090(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCommit_594089(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a commit for a repository on the tip of a specified branch.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594091 = header.getOrDefault("X-Amz-Date")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Date", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Security-Token")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Security-Token", valid_594092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594093 = header.getOrDefault("X-Amz-Target")
  valid_594093 = validateParameter(valid_594093, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateCommit"))
  if valid_594093 != nil:
    section.add "X-Amz-Target", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Content-Sha256", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Algorithm")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Algorithm", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Signature")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Signature", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-SignedHeaders", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Credential")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Credential", valid_594098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594100: Call_CreateCommit_594088; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a commit for a repository on the tip of a specified branch.
  ## 
  let valid = call_594100.validator(path, query, header, formData, body)
  let scheme = call_594100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594100.url(scheme.get, call_594100.host, call_594100.base,
                         call_594100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594100, url, valid)

proc call*(call_594101: Call_CreateCommit_594088; body: JsonNode): Recallable =
  ## createCommit
  ## Creates a commit for a repository on the tip of a specified branch.
  ##   body: JObject (required)
  var body_594102 = newJObject()
  if body != nil:
    body_594102 = body
  result = call_594101.call(nil, nil, nil, nil, body_594102)

var createCommit* = Call_CreateCommit_594088(name: "createCommit",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateCommit",
    validator: validate_CreateCommit_594089, base: "/", url: url_CreateCommit_594090,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePullRequest_594103 = ref object of OpenApiRestCall_593437
proc url_CreatePullRequest_594105(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePullRequest_594104(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates a pull request in the specified repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594106 = header.getOrDefault("X-Amz-Date")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Date", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Security-Token")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Security-Token", valid_594107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594108 = header.getOrDefault("X-Amz-Target")
  valid_594108 = validateParameter(valid_594108, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreatePullRequest"))
  if valid_594108 != nil:
    section.add "X-Amz-Target", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Content-Sha256", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Algorithm")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Algorithm", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Signature")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Signature", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-SignedHeaders", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Credential")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Credential", valid_594113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594115: Call_CreatePullRequest_594103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a pull request in the specified repository.
  ## 
  let valid = call_594115.validator(path, query, header, formData, body)
  let scheme = call_594115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594115.url(scheme.get, call_594115.host, call_594115.base,
                         call_594115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594115, url, valid)

proc call*(call_594116: Call_CreatePullRequest_594103; body: JsonNode): Recallable =
  ## createPullRequest
  ## Creates a pull request in the specified repository.
  ##   body: JObject (required)
  var body_594117 = newJObject()
  if body != nil:
    body_594117 = body
  result = call_594116.call(nil, nil, nil, nil, body_594117)

var createPullRequest* = Call_CreatePullRequest_594103(name: "createPullRequest",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreatePullRequest",
    validator: validate_CreatePullRequest_594104, base: "/",
    url: url_CreatePullRequest_594105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRepository_594118 = ref object of OpenApiRestCall_593437
proc url_CreateRepository_594120(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRepository_594119(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a new, empty repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594121 = header.getOrDefault("X-Amz-Date")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Date", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Security-Token")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Security-Token", valid_594122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594123 = header.getOrDefault("X-Amz-Target")
  valid_594123 = validateParameter(valid_594123, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateRepository"))
  if valid_594123 != nil:
    section.add "X-Amz-Target", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Content-Sha256", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Algorithm")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Algorithm", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Signature")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Signature", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-SignedHeaders", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Credential")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Credential", valid_594128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594130: Call_CreateRepository_594118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new, empty repository.
  ## 
  let valid = call_594130.validator(path, query, header, formData, body)
  let scheme = call_594130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594130.url(scheme.get, call_594130.host, call_594130.base,
                         call_594130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594130, url, valid)

proc call*(call_594131: Call_CreateRepository_594118; body: JsonNode): Recallable =
  ## createRepository
  ## Creates a new, empty repository.
  ##   body: JObject (required)
  var body_594132 = newJObject()
  if body != nil:
    body_594132 = body
  result = call_594131.call(nil, nil, nil, nil, body_594132)

var createRepository* = Call_CreateRepository_594118(name: "createRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateRepository",
    validator: validate_CreateRepository_594119, base: "/",
    url: url_CreateRepository_594120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUnreferencedMergeCommit_594133 = ref object of OpenApiRestCall_593437
proc url_CreateUnreferencedMergeCommit_594135(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateUnreferencedMergeCommit_594134(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an unreferenced commit that represents the result of merging two branches using a specified merge strategy. This can help you determine the outcome of a potential merge. This API cannot be used with the fast-forward merge strategy, as that strategy does not create a merge commit.</p> <note> <p>This unreferenced merge commit can only be accessed using the GetCommit API or through git commands such as git fetch. To retrieve this commit, you must specify its commit ID or otherwise reference it.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594136 = header.getOrDefault("X-Amz-Date")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Date", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Security-Token")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Security-Token", valid_594137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594138 = header.getOrDefault("X-Amz-Target")
  valid_594138 = validateParameter(valid_594138, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateUnreferencedMergeCommit"))
  if valid_594138 != nil:
    section.add "X-Amz-Target", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Content-Sha256", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Algorithm")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Algorithm", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-Signature")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Signature", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-SignedHeaders", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Credential")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Credential", valid_594143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594145: Call_CreateUnreferencedMergeCommit_594133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an unreferenced commit that represents the result of merging two branches using a specified merge strategy. This can help you determine the outcome of a potential merge. This API cannot be used with the fast-forward merge strategy, as that strategy does not create a merge commit.</p> <note> <p>This unreferenced merge commit can only be accessed using the GetCommit API or through git commands such as git fetch. To retrieve this commit, you must specify its commit ID or otherwise reference it.</p> </note>
  ## 
  let valid = call_594145.validator(path, query, header, formData, body)
  let scheme = call_594145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594145.url(scheme.get, call_594145.host, call_594145.base,
                         call_594145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594145, url, valid)

proc call*(call_594146: Call_CreateUnreferencedMergeCommit_594133; body: JsonNode): Recallable =
  ## createUnreferencedMergeCommit
  ## <p>Creates an unreferenced commit that represents the result of merging two branches using a specified merge strategy. This can help you determine the outcome of a potential merge. This API cannot be used with the fast-forward merge strategy, as that strategy does not create a merge commit.</p> <note> <p>This unreferenced merge commit can only be accessed using the GetCommit API or through git commands such as git fetch. To retrieve this commit, you must specify its commit ID or otherwise reference it.</p> </note>
  ##   body: JObject (required)
  var body_594147 = newJObject()
  if body != nil:
    body_594147 = body
  result = call_594146.call(nil, nil, nil, nil, body_594147)

var createUnreferencedMergeCommit* = Call_CreateUnreferencedMergeCommit_594133(
    name: "createUnreferencedMergeCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateUnreferencedMergeCommit",
    validator: validate_CreateUnreferencedMergeCommit_594134, base: "/",
    url: url_CreateUnreferencedMergeCommit_594135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBranch_594148 = ref object of OpenApiRestCall_593437
proc url_DeleteBranch_594150(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteBranch_594149(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a branch from a repository, unless that branch is the default branch for the repository. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594151 = header.getOrDefault("X-Amz-Date")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Date", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Security-Token")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Security-Token", valid_594152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594153 = header.getOrDefault("X-Amz-Target")
  valid_594153 = validateParameter(valid_594153, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteBranch"))
  if valid_594153 != nil:
    section.add "X-Amz-Target", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Content-Sha256", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Algorithm")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Algorithm", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Signature")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Signature", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-SignedHeaders", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Credential")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Credential", valid_594158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594160: Call_DeleteBranch_594148; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a branch from a repository, unless that branch is the default branch for the repository. 
  ## 
  let valid = call_594160.validator(path, query, header, formData, body)
  let scheme = call_594160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594160.url(scheme.get, call_594160.host, call_594160.base,
                         call_594160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594160, url, valid)

proc call*(call_594161: Call_DeleteBranch_594148; body: JsonNode): Recallable =
  ## deleteBranch
  ## Deletes a branch from a repository, unless that branch is the default branch for the repository. 
  ##   body: JObject (required)
  var body_594162 = newJObject()
  if body != nil:
    body_594162 = body
  result = call_594161.call(nil, nil, nil, nil, body_594162)

var deleteBranch* = Call_DeleteBranch_594148(name: "deleteBranch",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteBranch",
    validator: validate_DeleteBranch_594149, base: "/", url: url_DeleteBranch_594150,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCommentContent_594163 = ref object of OpenApiRestCall_593437
proc url_DeleteCommentContent_594165(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteCommentContent_594164(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the content of a comment made on a change, file, or commit in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594166 = header.getOrDefault("X-Amz-Date")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Date", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Security-Token")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Security-Token", valid_594167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594168 = header.getOrDefault("X-Amz-Target")
  valid_594168 = validateParameter(valid_594168, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteCommentContent"))
  if valid_594168 != nil:
    section.add "X-Amz-Target", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Content-Sha256", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Algorithm")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Algorithm", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Signature")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Signature", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-SignedHeaders", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Credential")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Credential", valid_594173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594175: Call_DeleteCommentContent_594163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the content of a comment made on a change, file, or commit in a repository.
  ## 
  let valid = call_594175.validator(path, query, header, formData, body)
  let scheme = call_594175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594175.url(scheme.get, call_594175.host, call_594175.base,
                         call_594175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594175, url, valid)

proc call*(call_594176: Call_DeleteCommentContent_594163; body: JsonNode): Recallable =
  ## deleteCommentContent
  ## Deletes the content of a comment made on a change, file, or commit in a repository.
  ##   body: JObject (required)
  var body_594177 = newJObject()
  if body != nil:
    body_594177 = body
  result = call_594176.call(nil, nil, nil, nil, body_594177)

var deleteCommentContent* = Call_DeleteCommentContent_594163(
    name: "deleteCommentContent", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteCommentContent",
    validator: validate_DeleteCommentContent_594164, base: "/",
    url: url_DeleteCommentContent_594165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFile_594178 = ref object of OpenApiRestCall_593437
proc url_DeleteFile_594180(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteFile_594179(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified file from a specified branch. A commit is created on the branch that contains the revision. The file will still exist in the commits prior to the commit that contains the deletion.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594181 = header.getOrDefault("X-Amz-Date")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Date", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Security-Token")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Security-Token", valid_594182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594183 = header.getOrDefault("X-Amz-Target")
  valid_594183 = validateParameter(valid_594183, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteFile"))
  if valid_594183 != nil:
    section.add "X-Amz-Target", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Content-Sha256", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Algorithm")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Algorithm", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-Signature")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Signature", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-SignedHeaders", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-Credential")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Credential", valid_594188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594190: Call_DeleteFile_594178; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified file from a specified branch. A commit is created on the branch that contains the revision. The file will still exist in the commits prior to the commit that contains the deletion.
  ## 
  let valid = call_594190.validator(path, query, header, formData, body)
  let scheme = call_594190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594190.url(scheme.get, call_594190.host, call_594190.base,
                         call_594190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594190, url, valid)

proc call*(call_594191: Call_DeleteFile_594178; body: JsonNode): Recallable =
  ## deleteFile
  ## Deletes a specified file from a specified branch. A commit is created on the branch that contains the revision. The file will still exist in the commits prior to the commit that contains the deletion.
  ##   body: JObject (required)
  var body_594192 = newJObject()
  if body != nil:
    body_594192 = body
  result = call_594191.call(nil, nil, nil, nil, body_594192)

var deleteFile* = Call_DeleteFile_594178(name: "deleteFile",
                                      meth: HttpMethod.HttpPost,
                                      host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.DeleteFile",
                                      validator: validate_DeleteFile_594179,
                                      base: "/", url: url_DeleteFile_594180,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRepository_594193 = ref object of OpenApiRestCall_593437
proc url_DeleteRepository_594195(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRepository_594194(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes a repository. If a specified repository was already deleted, a null repository ID will be returned.</p> <important> <p>Deleting a repository also deletes all associated objects and metadata. After a repository is deleted, all future push calls to the deleted repository will fail.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594196 = header.getOrDefault("X-Amz-Date")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Date", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Security-Token")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Security-Token", valid_594197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594198 = header.getOrDefault("X-Amz-Target")
  valid_594198 = validateParameter(valid_594198, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteRepository"))
  if valid_594198 != nil:
    section.add "X-Amz-Target", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Content-Sha256", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Algorithm")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Algorithm", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Signature")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Signature", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-SignedHeaders", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Credential")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Credential", valid_594203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594205: Call_DeleteRepository_594193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a repository. If a specified repository was already deleted, a null repository ID will be returned.</p> <important> <p>Deleting a repository also deletes all associated objects and metadata. After a repository is deleted, all future push calls to the deleted repository will fail.</p> </important>
  ## 
  let valid = call_594205.validator(path, query, header, formData, body)
  let scheme = call_594205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594205.url(scheme.get, call_594205.host, call_594205.base,
                         call_594205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594205, url, valid)

proc call*(call_594206: Call_DeleteRepository_594193; body: JsonNode): Recallable =
  ## deleteRepository
  ## <p>Deletes a repository. If a specified repository was already deleted, a null repository ID will be returned.</p> <important> <p>Deleting a repository also deletes all associated objects and metadata. After a repository is deleted, all future push calls to the deleted repository will fail.</p> </important>
  ##   body: JObject (required)
  var body_594207 = newJObject()
  if body != nil:
    body_594207 = body
  result = call_594206.call(nil, nil, nil, nil, body_594207)

var deleteRepository* = Call_DeleteRepository_594193(name: "deleteRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteRepository",
    validator: validate_DeleteRepository_594194, base: "/",
    url: url_DeleteRepository_594195, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMergeConflicts_594208 = ref object of OpenApiRestCall_593437
proc url_DescribeMergeConflicts_594210(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMergeConflicts_594209(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy. If the merge option for the attempted merge is specified as FAST_FORWARD_MERGE, an exception will be thrown.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxMergeHunks: JString
  ##                : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594211 = query.getOrDefault("maxMergeHunks")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "maxMergeHunks", valid_594211
  var valid_594212 = query.getOrDefault("nextToken")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "nextToken", valid_594212
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594213 = header.getOrDefault("X-Amz-Date")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Date", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Security-Token")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Security-Token", valid_594214
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594215 = header.getOrDefault("X-Amz-Target")
  valid_594215 = validateParameter(valid_594215, JString, required = true, default = newJString(
      "CodeCommit_20150413.DescribeMergeConflicts"))
  if valid_594215 != nil:
    section.add "X-Amz-Target", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Content-Sha256", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-Algorithm")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-Algorithm", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Signature")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Signature", valid_594218
  var valid_594219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594219 = validateParameter(valid_594219, JString, required = false,
                                 default = nil)
  if valid_594219 != nil:
    section.add "X-Amz-SignedHeaders", valid_594219
  var valid_594220 = header.getOrDefault("X-Amz-Credential")
  valid_594220 = validateParameter(valid_594220, JString, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "X-Amz-Credential", valid_594220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594222: Call_DescribeMergeConflicts_594208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy. If the merge option for the attempted merge is specified as FAST_FORWARD_MERGE, an exception will be thrown.
  ## 
  let valid = call_594222.validator(path, query, header, formData, body)
  let scheme = call_594222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594222.url(scheme.get, call_594222.host, call_594222.base,
                         call_594222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594222, url, valid)

proc call*(call_594223: Call_DescribeMergeConflicts_594208; body: JsonNode;
          maxMergeHunks: string = ""; nextToken: string = ""): Recallable =
  ## describeMergeConflicts
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy. If the merge option for the attempted merge is specified as FAST_FORWARD_MERGE, an exception will be thrown.
  ##   maxMergeHunks: string
  ##                : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594224 = newJObject()
  var body_594225 = newJObject()
  add(query_594224, "maxMergeHunks", newJString(maxMergeHunks))
  add(query_594224, "nextToken", newJString(nextToken))
  if body != nil:
    body_594225 = body
  result = call_594223.call(nil, query_594224, nil, nil, body_594225)

var describeMergeConflicts* = Call_DescribeMergeConflicts_594208(
    name: "describeMergeConflicts", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DescribeMergeConflicts",
    validator: validate_DescribeMergeConflicts_594209, base: "/",
    url: url_DescribeMergeConflicts_594210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePullRequestEvents_594227 = ref object of OpenApiRestCall_593437
proc url_DescribePullRequestEvents_594229(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePullRequestEvents_594228(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about one or more pull request events.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594230 = query.getOrDefault("maxResults")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "maxResults", valid_594230
  var valid_594231 = query.getOrDefault("nextToken")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "nextToken", valid_594231
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594232 = header.getOrDefault("X-Amz-Date")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "X-Amz-Date", valid_594232
  var valid_594233 = header.getOrDefault("X-Amz-Security-Token")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "X-Amz-Security-Token", valid_594233
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594234 = header.getOrDefault("X-Amz-Target")
  valid_594234 = validateParameter(valid_594234, JString, required = true, default = newJString(
      "CodeCommit_20150413.DescribePullRequestEvents"))
  if valid_594234 != nil:
    section.add "X-Amz-Target", valid_594234
  var valid_594235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594235 = validateParameter(valid_594235, JString, required = false,
                                 default = nil)
  if valid_594235 != nil:
    section.add "X-Amz-Content-Sha256", valid_594235
  var valid_594236 = header.getOrDefault("X-Amz-Algorithm")
  valid_594236 = validateParameter(valid_594236, JString, required = false,
                                 default = nil)
  if valid_594236 != nil:
    section.add "X-Amz-Algorithm", valid_594236
  var valid_594237 = header.getOrDefault("X-Amz-Signature")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "X-Amz-Signature", valid_594237
  var valid_594238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "X-Amz-SignedHeaders", valid_594238
  var valid_594239 = header.getOrDefault("X-Amz-Credential")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Credential", valid_594239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594241: Call_DescribePullRequestEvents_594227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about one or more pull request events.
  ## 
  let valid = call_594241.validator(path, query, header, formData, body)
  let scheme = call_594241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594241.url(scheme.get, call_594241.host, call_594241.base,
                         call_594241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594241, url, valid)

proc call*(call_594242: Call_DescribePullRequestEvents_594227; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describePullRequestEvents
  ## Returns information about one or more pull request events.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594243 = newJObject()
  var body_594244 = newJObject()
  add(query_594243, "maxResults", newJString(maxResults))
  add(query_594243, "nextToken", newJString(nextToken))
  if body != nil:
    body_594244 = body
  result = call_594242.call(nil, query_594243, nil, nil, body_594244)

var describePullRequestEvents* = Call_DescribePullRequestEvents_594227(
    name: "describePullRequestEvents", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DescribePullRequestEvents",
    validator: validate_DescribePullRequestEvents_594228, base: "/",
    url: url_DescribePullRequestEvents_594229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlob_594245 = ref object of OpenApiRestCall_593437
proc url_GetBlob_594247(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBlob_594246(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the base-64 encoded content of an individual blob within a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594248 = header.getOrDefault("X-Amz-Date")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-Date", valid_594248
  var valid_594249 = header.getOrDefault("X-Amz-Security-Token")
  valid_594249 = validateParameter(valid_594249, JString, required = false,
                                 default = nil)
  if valid_594249 != nil:
    section.add "X-Amz-Security-Token", valid_594249
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594250 = header.getOrDefault("X-Amz-Target")
  valid_594250 = validateParameter(valid_594250, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetBlob"))
  if valid_594250 != nil:
    section.add "X-Amz-Target", valid_594250
  var valid_594251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594251 = validateParameter(valid_594251, JString, required = false,
                                 default = nil)
  if valid_594251 != nil:
    section.add "X-Amz-Content-Sha256", valid_594251
  var valid_594252 = header.getOrDefault("X-Amz-Algorithm")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "X-Amz-Algorithm", valid_594252
  var valid_594253 = header.getOrDefault("X-Amz-Signature")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "X-Amz-Signature", valid_594253
  var valid_594254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-SignedHeaders", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Credential")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Credential", valid_594255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594257: Call_GetBlob_594245; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the base-64 encoded content of an individual blob within a repository.
  ## 
  let valid = call_594257.validator(path, query, header, formData, body)
  let scheme = call_594257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594257.url(scheme.get, call_594257.host, call_594257.base,
                         call_594257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594257, url, valid)

proc call*(call_594258: Call_GetBlob_594245; body: JsonNode): Recallable =
  ## getBlob
  ## Returns the base-64 encoded content of an individual blob within a repository.
  ##   body: JObject (required)
  var body_594259 = newJObject()
  if body != nil:
    body_594259 = body
  result = call_594258.call(nil, nil, nil, nil, body_594259)

var getBlob* = Call_GetBlob_594245(name: "getBlob", meth: HttpMethod.HttpPost,
                                host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetBlob",
                                validator: validate_GetBlob_594246, base: "/",
                                url: url_GetBlob_594247,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBranch_594260 = ref object of OpenApiRestCall_593437
proc url_GetBranch_594262(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBranch_594261(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a repository branch, including its name and the last commit ID.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594263 = header.getOrDefault("X-Amz-Date")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Date", valid_594263
  var valid_594264 = header.getOrDefault("X-Amz-Security-Token")
  valid_594264 = validateParameter(valid_594264, JString, required = false,
                                 default = nil)
  if valid_594264 != nil:
    section.add "X-Amz-Security-Token", valid_594264
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594265 = header.getOrDefault("X-Amz-Target")
  valid_594265 = validateParameter(valid_594265, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetBranch"))
  if valid_594265 != nil:
    section.add "X-Amz-Target", valid_594265
  var valid_594266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "X-Amz-Content-Sha256", valid_594266
  var valid_594267 = header.getOrDefault("X-Amz-Algorithm")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-Algorithm", valid_594267
  var valid_594268 = header.getOrDefault("X-Amz-Signature")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "X-Amz-Signature", valid_594268
  var valid_594269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "X-Amz-SignedHeaders", valid_594269
  var valid_594270 = header.getOrDefault("X-Amz-Credential")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "X-Amz-Credential", valid_594270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594272: Call_GetBranch_594260; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a repository branch, including its name and the last commit ID.
  ## 
  let valid = call_594272.validator(path, query, header, formData, body)
  let scheme = call_594272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594272.url(scheme.get, call_594272.host, call_594272.base,
                         call_594272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594272, url, valid)

proc call*(call_594273: Call_GetBranch_594260; body: JsonNode): Recallable =
  ## getBranch
  ## Returns information about a repository branch, including its name and the last commit ID.
  ##   body: JObject (required)
  var body_594274 = newJObject()
  if body != nil:
    body_594274 = body
  result = call_594273.call(nil, nil, nil, nil, body_594274)

var getBranch* = Call_GetBranch_594260(name: "getBranch", meth: HttpMethod.HttpPost,
                                    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetBranch",
                                    validator: validate_GetBranch_594261,
                                    base: "/", url: url_GetBranch_594262,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComment_594275 = ref object of OpenApiRestCall_593437
proc url_GetComment_594277(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetComment_594276(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the content of a comment made on a change, file, or commit in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594278 = header.getOrDefault("X-Amz-Date")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "X-Amz-Date", valid_594278
  var valid_594279 = header.getOrDefault("X-Amz-Security-Token")
  valid_594279 = validateParameter(valid_594279, JString, required = false,
                                 default = nil)
  if valid_594279 != nil:
    section.add "X-Amz-Security-Token", valid_594279
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594280 = header.getOrDefault("X-Amz-Target")
  valid_594280 = validateParameter(valid_594280, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetComment"))
  if valid_594280 != nil:
    section.add "X-Amz-Target", valid_594280
  var valid_594281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594281 = validateParameter(valid_594281, JString, required = false,
                                 default = nil)
  if valid_594281 != nil:
    section.add "X-Amz-Content-Sha256", valid_594281
  var valid_594282 = header.getOrDefault("X-Amz-Algorithm")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "X-Amz-Algorithm", valid_594282
  var valid_594283 = header.getOrDefault("X-Amz-Signature")
  valid_594283 = validateParameter(valid_594283, JString, required = false,
                                 default = nil)
  if valid_594283 != nil:
    section.add "X-Amz-Signature", valid_594283
  var valid_594284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594284 = validateParameter(valid_594284, JString, required = false,
                                 default = nil)
  if valid_594284 != nil:
    section.add "X-Amz-SignedHeaders", valid_594284
  var valid_594285 = header.getOrDefault("X-Amz-Credential")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "X-Amz-Credential", valid_594285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594287: Call_GetComment_594275; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the content of a comment made on a change, file, or commit in a repository.
  ## 
  let valid = call_594287.validator(path, query, header, formData, body)
  let scheme = call_594287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594287.url(scheme.get, call_594287.host, call_594287.base,
                         call_594287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594287, url, valid)

proc call*(call_594288: Call_GetComment_594275; body: JsonNode): Recallable =
  ## getComment
  ## Returns the content of a comment made on a change, file, or commit in a repository.
  ##   body: JObject (required)
  var body_594289 = newJObject()
  if body != nil:
    body_594289 = body
  result = call_594288.call(nil, nil, nil, nil, body_594289)

var getComment* = Call_GetComment_594275(name: "getComment",
                                      meth: HttpMethod.HttpPost,
                                      host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetComment",
                                      validator: validate_GetComment_594276,
                                      base: "/", url: url_GetComment_594277,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommentsForComparedCommit_594290 = ref object of OpenApiRestCall_593437
proc url_GetCommentsForComparedCommit_594292(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCommentsForComparedCommit_594291(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about comments made on the comparison between two commits.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594293 = query.getOrDefault("maxResults")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "maxResults", valid_594293
  var valid_594294 = query.getOrDefault("nextToken")
  valid_594294 = validateParameter(valid_594294, JString, required = false,
                                 default = nil)
  if valid_594294 != nil:
    section.add "nextToken", valid_594294
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594295 = header.getOrDefault("X-Amz-Date")
  valid_594295 = validateParameter(valid_594295, JString, required = false,
                                 default = nil)
  if valid_594295 != nil:
    section.add "X-Amz-Date", valid_594295
  var valid_594296 = header.getOrDefault("X-Amz-Security-Token")
  valid_594296 = validateParameter(valid_594296, JString, required = false,
                                 default = nil)
  if valid_594296 != nil:
    section.add "X-Amz-Security-Token", valid_594296
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594297 = header.getOrDefault("X-Amz-Target")
  valid_594297 = validateParameter(valid_594297, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommentsForComparedCommit"))
  if valid_594297 != nil:
    section.add "X-Amz-Target", valid_594297
  var valid_594298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594298 = validateParameter(valid_594298, JString, required = false,
                                 default = nil)
  if valid_594298 != nil:
    section.add "X-Amz-Content-Sha256", valid_594298
  var valid_594299 = header.getOrDefault("X-Amz-Algorithm")
  valid_594299 = validateParameter(valid_594299, JString, required = false,
                                 default = nil)
  if valid_594299 != nil:
    section.add "X-Amz-Algorithm", valid_594299
  var valid_594300 = header.getOrDefault("X-Amz-Signature")
  valid_594300 = validateParameter(valid_594300, JString, required = false,
                                 default = nil)
  if valid_594300 != nil:
    section.add "X-Amz-Signature", valid_594300
  var valid_594301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-SignedHeaders", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Credential")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Credential", valid_594302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594304: Call_GetCommentsForComparedCommit_594290; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about comments made on the comparison between two commits.
  ## 
  let valid = call_594304.validator(path, query, header, formData, body)
  let scheme = call_594304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594304.url(scheme.get, call_594304.host, call_594304.base,
                         call_594304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594304, url, valid)

proc call*(call_594305: Call_GetCommentsForComparedCommit_594290; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getCommentsForComparedCommit
  ## Returns information about comments made on the comparison between two commits.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594306 = newJObject()
  var body_594307 = newJObject()
  add(query_594306, "maxResults", newJString(maxResults))
  add(query_594306, "nextToken", newJString(nextToken))
  if body != nil:
    body_594307 = body
  result = call_594305.call(nil, query_594306, nil, nil, body_594307)

var getCommentsForComparedCommit* = Call_GetCommentsForComparedCommit_594290(
    name: "getCommentsForComparedCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetCommentsForComparedCommit",
    validator: validate_GetCommentsForComparedCommit_594291, base: "/",
    url: url_GetCommentsForComparedCommit_594292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommentsForPullRequest_594308 = ref object of OpenApiRestCall_593437
proc url_GetCommentsForPullRequest_594310(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCommentsForPullRequest_594309(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns comments made on a pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594311 = query.getOrDefault("maxResults")
  valid_594311 = validateParameter(valid_594311, JString, required = false,
                                 default = nil)
  if valid_594311 != nil:
    section.add "maxResults", valid_594311
  var valid_594312 = query.getOrDefault("nextToken")
  valid_594312 = validateParameter(valid_594312, JString, required = false,
                                 default = nil)
  if valid_594312 != nil:
    section.add "nextToken", valid_594312
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594313 = header.getOrDefault("X-Amz-Date")
  valid_594313 = validateParameter(valid_594313, JString, required = false,
                                 default = nil)
  if valid_594313 != nil:
    section.add "X-Amz-Date", valid_594313
  var valid_594314 = header.getOrDefault("X-Amz-Security-Token")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "X-Amz-Security-Token", valid_594314
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594315 = header.getOrDefault("X-Amz-Target")
  valid_594315 = validateParameter(valid_594315, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommentsForPullRequest"))
  if valid_594315 != nil:
    section.add "X-Amz-Target", valid_594315
  var valid_594316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "X-Amz-Content-Sha256", valid_594316
  var valid_594317 = header.getOrDefault("X-Amz-Algorithm")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "X-Amz-Algorithm", valid_594317
  var valid_594318 = header.getOrDefault("X-Amz-Signature")
  valid_594318 = validateParameter(valid_594318, JString, required = false,
                                 default = nil)
  if valid_594318 != nil:
    section.add "X-Amz-Signature", valid_594318
  var valid_594319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-SignedHeaders", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-Credential")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-Credential", valid_594320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594322: Call_GetCommentsForPullRequest_594308; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns comments made on a pull request.
  ## 
  let valid = call_594322.validator(path, query, header, formData, body)
  let scheme = call_594322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594322.url(scheme.get, call_594322.host, call_594322.base,
                         call_594322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594322, url, valid)

proc call*(call_594323: Call_GetCommentsForPullRequest_594308; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getCommentsForPullRequest
  ## Returns comments made on a pull request.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594324 = newJObject()
  var body_594325 = newJObject()
  add(query_594324, "maxResults", newJString(maxResults))
  add(query_594324, "nextToken", newJString(nextToken))
  if body != nil:
    body_594325 = body
  result = call_594323.call(nil, query_594324, nil, nil, body_594325)

var getCommentsForPullRequest* = Call_GetCommentsForPullRequest_594308(
    name: "getCommentsForPullRequest", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetCommentsForPullRequest",
    validator: validate_GetCommentsForPullRequest_594309, base: "/",
    url: url_GetCommentsForPullRequest_594310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommit_594326 = ref object of OpenApiRestCall_593437
proc url_GetCommit_594328(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCommit_594327(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a commit, including commit message and committer information.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594329 = header.getOrDefault("X-Amz-Date")
  valid_594329 = validateParameter(valid_594329, JString, required = false,
                                 default = nil)
  if valid_594329 != nil:
    section.add "X-Amz-Date", valid_594329
  var valid_594330 = header.getOrDefault("X-Amz-Security-Token")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "X-Amz-Security-Token", valid_594330
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594331 = header.getOrDefault("X-Amz-Target")
  valid_594331 = validateParameter(valid_594331, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommit"))
  if valid_594331 != nil:
    section.add "X-Amz-Target", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Content-Sha256", valid_594332
  var valid_594333 = header.getOrDefault("X-Amz-Algorithm")
  valid_594333 = validateParameter(valid_594333, JString, required = false,
                                 default = nil)
  if valid_594333 != nil:
    section.add "X-Amz-Algorithm", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-Signature")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Signature", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-SignedHeaders", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Credential")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Credential", valid_594336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594338: Call_GetCommit_594326; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a commit, including commit message and committer information.
  ## 
  let valid = call_594338.validator(path, query, header, formData, body)
  let scheme = call_594338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594338.url(scheme.get, call_594338.host, call_594338.base,
                         call_594338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594338, url, valid)

proc call*(call_594339: Call_GetCommit_594326; body: JsonNode): Recallable =
  ## getCommit
  ## Returns information about a commit, including commit message and committer information.
  ##   body: JObject (required)
  var body_594340 = newJObject()
  if body != nil:
    body_594340 = body
  result = call_594339.call(nil, nil, nil, nil, body_594340)

var getCommit* = Call_GetCommit_594326(name: "getCommit", meth: HttpMethod.HttpPost,
                                    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetCommit",
                                    validator: validate_GetCommit_594327,
                                    base: "/", url: url_GetCommit_594328,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDifferences_594341 = ref object of OpenApiRestCall_593437
proc url_GetDifferences_594343(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDifferences_594342(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID or other fully qualified reference). Results can be limited to a specified path.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594344 = query.getOrDefault("NextToken")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "NextToken", valid_594344
  var valid_594345 = query.getOrDefault("MaxResults")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "MaxResults", valid_594345
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594346 = header.getOrDefault("X-Amz-Date")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Date", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-Security-Token")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Security-Token", valid_594347
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594348 = header.getOrDefault("X-Amz-Target")
  valid_594348 = validateParameter(valid_594348, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetDifferences"))
  if valid_594348 != nil:
    section.add "X-Amz-Target", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Content-Sha256", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-Algorithm")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Algorithm", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-Signature")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-Signature", valid_594351
  var valid_594352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-SignedHeaders", valid_594352
  var valid_594353 = header.getOrDefault("X-Amz-Credential")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-Credential", valid_594353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594355: Call_GetDifferences_594341; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID or other fully qualified reference). Results can be limited to a specified path.
  ## 
  let valid = call_594355.validator(path, query, header, formData, body)
  let scheme = call_594355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594355.url(scheme.get, call_594355.host, call_594355.base,
                         call_594355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594355, url, valid)

proc call*(call_594356: Call_GetDifferences_594341; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getDifferences
  ## Returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID or other fully qualified reference). Results can be limited to a specified path.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594357 = newJObject()
  var body_594358 = newJObject()
  add(query_594357, "NextToken", newJString(NextToken))
  if body != nil:
    body_594358 = body
  add(query_594357, "MaxResults", newJString(MaxResults))
  result = call_594356.call(nil, query_594357, nil, nil, body_594358)

var getDifferences* = Call_GetDifferences_594341(name: "getDifferences",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetDifferences",
    validator: validate_GetDifferences_594342, base: "/", url: url_GetDifferences_594343,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFile_594359 = ref object of OpenApiRestCall_593437
proc url_GetFile_594361(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetFile_594360(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the base-64 encoded contents of a specified file and its metadata.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594362 = header.getOrDefault("X-Amz-Date")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "X-Amz-Date", valid_594362
  var valid_594363 = header.getOrDefault("X-Amz-Security-Token")
  valid_594363 = validateParameter(valid_594363, JString, required = false,
                                 default = nil)
  if valid_594363 != nil:
    section.add "X-Amz-Security-Token", valid_594363
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594364 = header.getOrDefault("X-Amz-Target")
  valid_594364 = validateParameter(valid_594364, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetFile"))
  if valid_594364 != nil:
    section.add "X-Amz-Target", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Content-Sha256", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Algorithm")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Algorithm", valid_594366
  var valid_594367 = header.getOrDefault("X-Amz-Signature")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-Signature", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-SignedHeaders", valid_594368
  var valid_594369 = header.getOrDefault("X-Amz-Credential")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-Credential", valid_594369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594371: Call_GetFile_594359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the base-64 encoded contents of a specified file and its metadata.
  ## 
  let valid = call_594371.validator(path, query, header, formData, body)
  let scheme = call_594371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594371.url(scheme.get, call_594371.host, call_594371.base,
                         call_594371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594371, url, valid)

proc call*(call_594372: Call_GetFile_594359; body: JsonNode): Recallable =
  ## getFile
  ## Returns the base-64 encoded contents of a specified file and its metadata.
  ##   body: JObject (required)
  var body_594373 = newJObject()
  if body != nil:
    body_594373 = body
  result = call_594372.call(nil, nil, nil, nil, body_594373)

var getFile* = Call_GetFile_594359(name: "getFile", meth: HttpMethod.HttpPost,
                                host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetFile",
                                validator: validate_GetFile_594360, base: "/",
                                url: url_GetFile_594361,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolder_594374 = ref object of OpenApiRestCall_593437
proc url_GetFolder_594376(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetFolder_594375(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the contents of a specified folder in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594377 = header.getOrDefault("X-Amz-Date")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "X-Amz-Date", valid_594377
  var valid_594378 = header.getOrDefault("X-Amz-Security-Token")
  valid_594378 = validateParameter(valid_594378, JString, required = false,
                                 default = nil)
  if valid_594378 != nil:
    section.add "X-Amz-Security-Token", valid_594378
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594379 = header.getOrDefault("X-Amz-Target")
  valid_594379 = validateParameter(valid_594379, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetFolder"))
  if valid_594379 != nil:
    section.add "X-Amz-Target", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Content-Sha256", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Algorithm")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Algorithm", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-Signature")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-Signature", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-SignedHeaders", valid_594383
  var valid_594384 = header.getOrDefault("X-Amz-Credential")
  valid_594384 = validateParameter(valid_594384, JString, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "X-Amz-Credential", valid_594384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594386: Call_GetFolder_594374; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the contents of a specified folder in a repository.
  ## 
  let valid = call_594386.validator(path, query, header, formData, body)
  let scheme = call_594386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594386.url(scheme.get, call_594386.host, call_594386.base,
                         call_594386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594386, url, valid)

proc call*(call_594387: Call_GetFolder_594374; body: JsonNode): Recallable =
  ## getFolder
  ## Returns the contents of a specified folder in a repository.
  ##   body: JObject (required)
  var body_594388 = newJObject()
  if body != nil:
    body_594388 = body
  result = call_594387.call(nil, nil, nil, nil, body_594388)

var getFolder* = Call_GetFolder_594374(name: "getFolder", meth: HttpMethod.HttpPost,
                                    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetFolder",
                                    validator: validate_GetFolder_594375,
                                    base: "/", url: url_GetFolder_594376,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeCommit_594389 = ref object of OpenApiRestCall_593437
proc url_GetMergeCommit_594391(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMergeCommit_594390(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns information about a specified merge commit.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594392 = header.getOrDefault("X-Amz-Date")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "X-Amz-Date", valid_594392
  var valid_594393 = header.getOrDefault("X-Amz-Security-Token")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "X-Amz-Security-Token", valid_594393
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594394 = header.getOrDefault("X-Amz-Target")
  valid_594394 = validateParameter(valid_594394, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeCommit"))
  if valid_594394 != nil:
    section.add "X-Amz-Target", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Content-Sha256", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Algorithm")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Algorithm", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-Signature")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-Signature", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-SignedHeaders", valid_594398
  var valid_594399 = header.getOrDefault("X-Amz-Credential")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "X-Amz-Credential", valid_594399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594401: Call_GetMergeCommit_594389; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified merge commit.
  ## 
  let valid = call_594401.validator(path, query, header, formData, body)
  let scheme = call_594401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594401.url(scheme.get, call_594401.host, call_594401.base,
                         call_594401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594401, url, valid)

proc call*(call_594402: Call_GetMergeCommit_594389; body: JsonNode): Recallable =
  ## getMergeCommit
  ## Returns information about a specified merge commit.
  ##   body: JObject (required)
  var body_594403 = newJObject()
  if body != nil:
    body_594403 = body
  result = call_594402.call(nil, nil, nil, nil, body_594403)

var getMergeCommit* = Call_GetMergeCommit_594389(name: "getMergeCommit",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeCommit",
    validator: validate_GetMergeCommit_594390, base: "/", url: url_GetMergeCommit_594391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeConflicts_594404 = ref object of OpenApiRestCall_593437
proc url_GetMergeConflicts_594406(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMergeConflicts_594405(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns information about merge conflicts between the before and after commit IDs for a pull request in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxConflictFiles: JString
  ##                   : Pagination limit
  section = newJObject()
  var valid_594407 = query.getOrDefault("nextToken")
  valid_594407 = validateParameter(valid_594407, JString, required = false,
                                 default = nil)
  if valid_594407 != nil:
    section.add "nextToken", valid_594407
  var valid_594408 = query.getOrDefault("maxConflictFiles")
  valid_594408 = validateParameter(valid_594408, JString, required = false,
                                 default = nil)
  if valid_594408 != nil:
    section.add "maxConflictFiles", valid_594408
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594409 = header.getOrDefault("X-Amz-Date")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "X-Amz-Date", valid_594409
  var valid_594410 = header.getOrDefault("X-Amz-Security-Token")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "X-Amz-Security-Token", valid_594410
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594411 = header.getOrDefault("X-Amz-Target")
  valid_594411 = validateParameter(valid_594411, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeConflicts"))
  if valid_594411 != nil:
    section.add "X-Amz-Target", valid_594411
  var valid_594412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-Content-Sha256", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-Algorithm")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Algorithm", valid_594413
  var valid_594414 = header.getOrDefault("X-Amz-Signature")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-Signature", valid_594414
  var valid_594415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "X-Amz-SignedHeaders", valid_594415
  var valid_594416 = header.getOrDefault("X-Amz-Credential")
  valid_594416 = validateParameter(valid_594416, JString, required = false,
                                 default = nil)
  if valid_594416 != nil:
    section.add "X-Amz-Credential", valid_594416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594418: Call_GetMergeConflicts_594404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about merge conflicts between the before and after commit IDs for a pull request in a repository.
  ## 
  let valid = call_594418.validator(path, query, header, formData, body)
  let scheme = call_594418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594418.url(scheme.get, call_594418.host, call_594418.base,
                         call_594418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594418, url, valid)

proc call*(call_594419: Call_GetMergeConflicts_594404; body: JsonNode;
          nextToken: string = ""; maxConflictFiles: string = ""): Recallable =
  ## getMergeConflicts
  ## Returns information about merge conflicts between the before and after commit IDs for a pull request in a repository.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxConflictFiles: string
  ##                   : Pagination limit
  var query_594420 = newJObject()
  var body_594421 = newJObject()
  add(query_594420, "nextToken", newJString(nextToken))
  if body != nil:
    body_594421 = body
  add(query_594420, "maxConflictFiles", newJString(maxConflictFiles))
  result = call_594419.call(nil, query_594420, nil, nil, body_594421)

var getMergeConflicts* = Call_GetMergeConflicts_594404(name: "getMergeConflicts",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeConflicts",
    validator: validate_GetMergeConflicts_594405, base: "/",
    url: url_GetMergeConflicts_594406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeOptions_594422 = ref object of OpenApiRestCall_593437
proc url_GetMergeOptions_594424(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMergeOptions_594423(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns information about the merge options available for merging two specified branches. For details about why a particular merge option is not available, use GetMergeConflicts or DescribeMergeConflicts.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594425 = header.getOrDefault("X-Amz-Date")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Date", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Security-Token")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Security-Token", valid_594426
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594427 = header.getOrDefault("X-Amz-Target")
  valid_594427 = validateParameter(valid_594427, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeOptions"))
  if valid_594427 != nil:
    section.add "X-Amz-Target", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Content-Sha256", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-Algorithm")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Algorithm", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-Signature")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-Signature", valid_594430
  var valid_594431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594431 = validateParameter(valid_594431, JString, required = false,
                                 default = nil)
  if valid_594431 != nil:
    section.add "X-Amz-SignedHeaders", valid_594431
  var valid_594432 = header.getOrDefault("X-Amz-Credential")
  valid_594432 = validateParameter(valid_594432, JString, required = false,
                                 default = nil)
  if valid_594432 != nil:
    section.add "X-Amz-Credential", valid_594432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594434: Call_GetMergeOptions_594422; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the merge options available for merging two specified branches. For details about why a particular merge option is not available, use GetMergeConflicts or DescribeMergeConflicts.
  ## 
  let valid = call_594434.validator(path, query, header, formData, body)
  let scheme = call_594434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594434.url(scheme.get, call_594434.host, call_594434.base,
                         call_594434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594434, url, valid)

proc call*(call_594435: Call_GetMergeOptions_594422; body: JsonNode): Recallable =
  ## getMergeOptions
  ## Returns information about the merge options available for merging two specified branches. For details about why a particular merge option is not available, use GetMergeConflicts or DescribeMergeConflicts.
  ##   body: JObject (required)
  var body_594436 = newJObject()
  if body != nil:
    body_594436 = body
  result = call_594435.call(nil, nil, nil, nil, body_594436)

var getMergeOptions* = Call_GetMergeOptions_594422(name: "getMergeOptions",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeOptions",
    validator: validate_GetMergeOptions_594423, base: "/", url: url_GetMergeOptions_594424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPullRequest_594437 = ref object of OpenApiRestCall_593437
proc url_GetPullRequest_594439(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPullRequest_594438(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets information about a pull request in a specified repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594440 = header.getOrDefault("X-Amz-Date")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Date", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Security-Token")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Security-Token", valid_594441
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594442 = header.getOrDefault("X-Amz-Target")
  valid_594442 = validateParameter(valid_594442, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetPullRequest"))
  if valid_594442 != nil:
    section.add "X-Amz-Target", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Content-Sha256", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-Algorithm")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-Algorithm", valid_594444
  var valid_594445 = header.getOrDefault("X-Amz-Signature")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "X-Amz-Signature", valid_594445
  var valid_594446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594446 = validateParameter(valid_594446, JString, required = false,
                                 default = nil)
  if valid_594446 != nil:
    section.add "X-Amz-SignedHeaders", valid_594446
  var valid_594447 = header.getOrDefault("X-Amz-Credential")
  valid_594447 = validateParameter(valid_594447, JString, required = false,
                                 default = nil)
  if valid_594447 != nil:
    section.add "X-Amz-Credential", valid_594447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594449: Call_GetPullRequest_594437; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a pull request in a specified repository.
  ## 
  let valid = call_594449.validator(path, query, header, formData, body)
  let scheme = call_594449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594449.url(scheme.get, call_594449.host, call_594449.base,
                         call_594449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594449, url, valid)

proc call*(call_594450: Call_GetPullRequest_594437; body: JsonNode): Recallable =
  ## getPullRequest
  ## Gets information about a pull request in a specified repository.
  ##   body: JObject (required)
  var body_594451 = newJObject()
  if body != nil:
    body_594451 = body
  result = call_594450.call(nil, nil, nil, nil, body_594451)

var getPullRequest* = Call_GetPullRequest_594437(name: "getPullRequest",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetPullRequest",
    validator: validate_GetPullRequest_594438, base: "/", url: url_GetPullRequest_594439,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepository_594452 = ref object of OpenApiRestCall_593437
proc url_GetRepository_594454(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRepository_594453(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594455 = header.getOrDefault("X-Amz-Date")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Date", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-Security-Token")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-Security-Token", valid_594456
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594457 = header.getOrDefault("X-Amz-Target")
  valid_594457 = validateParameter(valid_594457, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetRepository"))
  if valid_594457 != nil:
    section.add "X-Amz-Target", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Content-Sha256", valid_594458
  var valid_594459 = header.getOrDefault("X-Amz-Algorithm")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "X-Amz-Algorithm", valid_594459
  var valid_594460 = header.getOrDefault("X-Amz-Signature")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "X-Amz-Signature", valid_594460
  var valid_594461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594461 = validateParameter(valid_594461, JString, required = false,
                                 default = nil)
  if valid_594461 != nil:
    section.add "X-Amz-SignedHeaders", valid_594461
  var valid_594462 = header.getOrDefault("X-Amz-Credential")
  valid_594462 = validateParameter(valid_594462, JString, required = false,
                                 default = nil)
  if valid_594462 != nil:
    section.add "X-Amz-Credential", valid_594462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594464: Call_GetRepository_594452; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ## 
  let valid = call_594464.validator(path, query, header, formData, body)
  let scheme = call_594464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594464.url(scheme.get, call_594464.host, call_594464.base,
                         call_594464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594464, url, valid)

proc call*(call_594465: Call_GetRepository_594452; body: JsonNode): Recallable =
  ## getRepository
  ## <p>Returns information about a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ##   body: JObject (required)
  var body_594466 = newJObject()
  if body != nil:
    body_594466 = body
  result = call_594465.call(nil, nil, nil, nil, body_594466)

var getRepository* = Call_GetRepository_594452(name: "getRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetRepository",
    validator: validate_GetRepository_594453, base: "/", url: url_GetRepository_594454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepositoryTriggers_594467 = ref object of OpenApiRestCall_593437
proc url_GetRepositoryTriggers_594469(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRepositoryTriggers_594468(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about triggers configured for a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594470 = header.getOrDefault("X-Amz-Date")
  valid_594470 = validateParameter(valid_594470, JString, required = false,
                                 default = nil)
  if valid_594470 != nil:
    section.add "X-Amz-Date", valid_594470
  var valid_594471 = header.getOrDefault("X-Amz-Security-Token")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "X-Amz-Security-Token", valid_594471
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594472 = header.getOrDefault("X-Amz-Target")
  valid_594472 = validateParameter(valid_594472, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetRepositoryTriggers"))
  if valid_594472 != nil:
    section.add "X-Amz-Target", valid_594472
  var valid_594473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-Content-Sha256", valid_594473
  var valid_594474 = header.getOrDefault("X-Amz-Algorithm")
  valid_594474 = validateParameter(valid_594474, JString, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "X-Amz-Algorithm", valid_594474
  var valid_594475 = header.getOrDefault("X-Amz-Signature")
  valid_594475 = validateParameter(valid_594475, JString, required = false,
                                 default = nil)
  if valid_594475 != nil:
    section.add "X-Amz-Signature", valid_594475
  var valid_594476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594476 = validateParameter(valid_594476, JString, required = false,
                                 default = nil)
  if valid_594476 != nil:
    section.add "X-Amz-SignedHeaders", valid_594476
  var valid_594477 = header.getOrDefault("X-Amz-Credential")
  valid_594477 = validateParameter(valid_594477, JString, required = false,
                                 default = nil)
  if valid_594477 != nil:
    section.add "X-Amz-Credential", valid_594477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594479: Call_GetRepositoryTriggers_594467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about triggers configured for a repository.
  ## 
  let valid = call_594479.validator(path, query, header, formData, body)
  let scheme = call_594479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594479.url(scheme.get, call_594479.host, call_594479.base,
                         call_594479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594479, url, valid)

proc call*(call_594480: Call_GetRepositoryTriggers_594467; body: JsonNode): Recallable =
  ## getRepositoryTriggers
  ## Gets information about triggers configured for a repository.
  ##   body: JObject (required)
  var body_594481 = newJObject()
  if body != nil:
    body_594481 = body
  result = call_594480.call(nil, nil, nil, nil, body_594481)

var getRepositoryTriggers* = Call_GetRepositoryTriggers_594467(
    name: "getRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetRepositoryTriggers",
    validator: validate_GetRepositoryTriggers_594468, base: "/",
    url: url_GetRepositoryTriggers_594469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBranches_594482 = ref object of OpenApiRestCall_593437
proc url_ListBranches_594484(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBranches_594483(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about one or more branches in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594485 = query.getOrDefault("nextToken")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "nextToken", valid_594485
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594486 = header.getOrDefault("X-Amz-Date")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Date", valid_594486
  var valid_594487 = header.getOrDefault("X-Amz-Security-Token")
  valid_594487 = validateParameter(valid_594487, JString, required = false,
                                 default = nil)
  if valid_594487 != nil:
    section.add "X-Amz-Security-Token", valid_594487
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594488 = header.getOrDefault("X-Amz-Target")
  valid_594488 = validateParameter(valid_594488, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListBranches"))
  if valid_594488 != nil:
    section.add "X-Amz-Target", valid_594488
  var valid_594489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-Content-Sha256", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-Algorithm")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-Algorithm", valid_594490
  var valid_594491 = header.getOrDefault("X-Amz-Signature")
  valid_594491 = validateParameter(valid_594491, JString, required = false,
                                 default = nil)
  if valid_594491 != nil:
    section.add "X-Amz-Signature", valid_594491
  var valid_594492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594492 = validateParameter(valid_594492, JString, required = false,
                                 default = nil)
  if valid_594492 != nil:
    section.add "X-Amz-SignedHeaders", valid_594492
  var valid_594493 = header.getOrDefault("X-Amz-Credential")
  valid_594493 = validateParameter(valid_594493, JString, required = false,
                                 default = nil)
  if valid_594493 != nil:
    section.add "X-Amz-Credential", valid_594493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594495: Call_ListBranches_594482; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more branches in a repository.
  ## 
  let valid = call_594495.validator(path, query, header, formData, body)
  let scheme = call_594495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594495.url(scheme.get, call_594495.host, call_594495.base,
                         call_594495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594495, url, valid)

proc call*(call_594496: Call_ListBranches_594482; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listBranches
  ## Gets information about one or more branches in a repository.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594497 = newJObject()
  var body_594498 = newJObject()
  add(query_594497, "nextToken", newJString(nextToken))
  if body != nil:
    body_594498 = body
  result = call_594496.call(nil, query_594497, nil, nil, body_594498)

var listBranches* = Call_ListBranches_594482(name: "listBranches",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListBranches",
    validator: validate_ListBranches_594483, base: "/", url: url_ListBranches_594484,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPullRequests_594499 = ref object of OpenApiRestCall_593437
proc url_ListPullRequests_594501(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPullRequests_594500(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of pull requests for a specified repository. The return list can be refined by pull request status or pull request author ARN.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594502 = query.getOrDefault("maxResults")
  valid_594502 = validateParameter(valid_594502, JString, required = false,
                                 default = nil)
  if valid_594502 != nil:
    section.add "maxResults", valid_594502
  var valid_594503 = query.getOrDefault("nextToken")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "nextToken", valid_594503
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594504 = header.getOrDefault("X-Amz-Date")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "X-Amz-Date", valid_594504
  var valid_594505 = header.getOrDefault("X-Amz-Security-Token")
  valid_594505 = validateParameter(valid_594505, JString, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "X-Amz-Security-Token", valid_594505
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594506 = header.getOrDefault("X-Amz-Target")
  valid_594506 = validateParameter(valid_594506, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListPullRequests"))
  if valid_594506 != nil:
    section.add "X-Amz-Target", valid_594506
  var valid_594507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-Content-Sha256", valid_594507
  var valid_594508 = header.getOrDefault("X-Amz-Algorithm")
  valid_594508 = validateParameter(valid_594508, JString, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "X-Amz-Algorithm", valid_594508
  var valid_594509 = header.getOrDefault("X-Amz-Signature")
  valid_594509 = validateParameter(valid_594509, JString, required = false,
                                 default = nil)
  if valid_594509 != nil:
    section.add "X-Amz-Signature", valid_594509
  var valid_594510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594510 = validateParameter(valid_594510, JString, required = false,
                                 default = nil)
  if valid_594510 != nil:
    section.add "X-Amz-SignedHeaders", valid_594510
  var valid_594511 = header.getOrDefault("X-Amz-Credential")
  valid_594511 = validateParameter(valid_594511, JString, required = false,
                                 default = nil)
  if valid_594511 != nil:
    section.add "X-Amz-Credential", valid_594511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594513: Call_ListPullRequests_594499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of pull requests for a specified repository. The return list can be refined by pull request status or pull request author ARN.
  ## 
  let valid = call_594513.validator(path, query, header, formData, body)
  let scheme = call_594513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594513.url(scheme.get, call_594513.host, call_594513.base,
                         call_594513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594513, url, valid)

proc call*(call_594514: Call_ListPullRequests_594499; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listPullRequests
  ## Returns a list of pull requests for a specified repository. The return list can be refined by pull request status or pull request author ARN.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594515 = newJObject()
  var body_594516 = newJObject()
  add(query_594515, "maxResults", newJString(maxResults))
  add(query_594515, "nextToken", newJString(nextToken))
  if body != nil:
    body_594516 = body
  result = call_594514.call(nil, query_594515, nil, nil, body_594516)

var listPullRequests* = Call_ListPullRequests_594499(name: "listPullRequests",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListPullRequests",
    validator: validate_ListPullRequests_594500, base: "/",
    url: url_ListPullRequests_594501, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRepositories_594517 = ref object of OpenApiRestCall_593437
proc url_ListRepositories_594519(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRepositories_594518(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Gets information about one or more repositories.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594520 = query.getOrDefault("nextToken")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "nextToken", valid_594520
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594521 = header.getOrDefault("X-Amz-Date")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-Date", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-Security-Token")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Security-Token", valid_594522
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594523 = header.getOrDefault("X-Amz-Target")
  valid_594523 = validateParameter(valid_594523, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListRepositories"))
  if valid_594523 != nil:
    section.add "X-Amz-Target", valid_594523
  var valid_594524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594524 = validateParameter(valid_594524, JString, required = false,
                                 default = nil)
  if valid_594524 != nil:
    section.add "X-Amz-Content-Sha256", valid_594524
  var valid_594525 = header.getOrDefault("X-Amz-Algorithm")
  valid_594525 = validateParameter(valid_594525, JString, required = false,
                                 default = nil)
  if valid_594525 != nil:
    section.add "X-Amz-Algorithm", valid_594525
  var valid_594526 = header.getOrDefault("X-Amz-Signature")
  valid_594526 = validateParameter(valid_594526, JString, required = false,
                                 default = nil)
  if valid_594526 != nil:
    section.add "X-Amz-Signature", valid_594526
  var valid_594527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594527 = validateParameter(valid_594527, JString, required = false,
                                 default = nil)
  if valid_594527 != nil:
    section.add "X-Amz-SignedHeaders", valid_594527
  var valid_594528 = header.getOrDefault("X-Amz-Credential")
  valid_594528 = validateParameter(valid_594528, JString, required = false,
                                 default = nil)
  if valid_594528 != nil:
    section.add "X-Amz-Credential", valid_594528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594530: Call_ListRepositories_594517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more repositories.
  ## 
  let valid = call_594530.validator(path, query, header, formData, body)
  let scheme = call_594530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594530.url(scheme.get, call_594530.host, call_594530.base,
                         call_594530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594530, url, valid)

proc call*(call_594531: Call_ListRepositories_594517; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listRepositories
  ## Gets information about one or more repositories.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594532 = newJObject()
  var body_594533 = newJObject()
  add(query_594532, "nextToken", newJString(nextToken))
  if body != nil:
    body_594533 = body
  result = call_594531.call(nil, query_594532, nil, nil, body_594533)

var listRepositories* = Call_ListRepositories_594517(name: "listRepositories",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListRepositories",
    validator: validate_ListRepositories_594518, base: "/",
    url: url_ListRepositories_594519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594534 = ref object of OpenApiRestCall_593437
proc url_ListTagsForResource_594536(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_594535(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594537 = header.getOrDefault("X-Amz-Date")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "X-Amz-Date", valid_594537
  var valid_594538 = header.getOrDefault("X-Amz-Security-Token")
  valid_594538 = validateParameter(valid_594538, JString, required = false,
                                 default = nil)
  if valid_594538 != nil:
    section.add "X-Amz-Security-Token", valid_594538
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594539 = header.getOrDefault("X-Amz-Target")
  valid_594539 = validateParameter(valid_594539, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListTagsForResource"))
  if valid_594539 != nil:
    section.add "X-Amz-Target", valid_594539
  var valid_594540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594540 = validateParameter(valid_594540, JString, required = false,
                                 default = nil)
  if valid_594540 != nil:
    section.add "X-Amz-Content-Sha256", valid_594540
  var valid_594541 = header.getOrDefault("X-Amz-Algorithm")
  valid_594541 = validateParameter(valid_594541, JString, required = false,
                                 default = nil)
  if valid_594541 != nil:
    section.add "X-Amz-Algorithm", valid_594541
  var valid_594542 = header.getOrDefault("X-Amz-Signature")
  valid_594542 = validateParameter(valid_594542, JString, required = false,
                                 default = nil)
  if valid_594542 != nil:
    section.add "X-Amz-Signature", valid_594542
  var valid_594543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594543 = validateParameter(valid_594543, JString, required = false,
                                 default = nil)
  if valid_594543 != nil:
    section.add "X-Amz-SignedHeaders", valid_594543
  var valid_594544 = header.getOrDefault("X-Amz-Credential")
  valid_594544 = validateParameter(valid_594544, JString, required = false,
                                 default = nil)
  if valid_594544 != nil:
    section.add "X-Amz-Credential", valid_594544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594546: Call_ListTagsForResource_594534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ## 
  let valid = call_594546.validator(path, query, header, formData, body)
  let scheme = call_594546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594546.url(scheme.get, call_594546.host, call_594546.base,
                         call_594546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594546, url, valid)

proc call*(call_594547: Call_ListTagsForResource_594534; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ##   body: JObject (required)
  var body_594548 = newJObject()
  if body != nil:
    body_594548 = body
  result = call_594547.call(nil, nil, nil, nil, body_594548)

var listTagsForResource* = Call_ListTagsForResource_594534(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListTagsForResource",
    validator: validate_ListTagsForResource_594535, base: "/",
    url: url_ListTagsForResource_594536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesByFastForward_594549 = ref object of OpenApiRestCall_593437
proc url_MergeBranchesByFastForward_594551(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_MergeBranchesByFastForward_594550(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Merges two branches using the fast-forward merge strategy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594552 = header.getOrDefault("X-Amz-Date")
  valid_594552 = validateParameter(valid_594552, JString, required = false,
                                 default = nil)
  if valid_594552 != nil:
    section.add "X-Amz-Date", valid_594552
  var valid_594553 = header.getOrDefault("X-Amz-Security-Token")
  valid_594553 = validateParameter(valid_594553, JString, required = false,
                                 default = nil)
  if valid_594553 != nil:
    section.add "X-Amz-Security-Token", valid_594553
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594554 = header.getOrDefault("X-Amz-Target")
  valid_594554 = validateParameter(valid_594554, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesByFastForward"))
  if valid_594554 != nil:
    section.add "X-Amz-Target", valid_594554
  var valid_594555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594555 = validateParameter(valid_594555, JString, required = false,
                                 default = nil)
  if valid_594555 != nil:
    section.add "X-Amz-Content-Sha256", valid_594555
  var valid_594556 = header.getOrDefault("X-Amz-Algorithm")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-Algorithm", valid_594556
  var valid_594557 = header.getOrDefault("X-Amz-Signature")
  valid_594557 = validateParameter(valid_594557, JString, required = false,
                                 default = nil)
  if valid_594557 != nil:
    section.add "X-Amz-Signature", valid_594557
  var valid_594558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594558 = validateParameter(valid_594558, JString, required = false,
                                 default = nil)
  if valid_594558 != nil:
    section.add "X-Amz-SignedHeaders", valid_594558
  var valid_594559 = header.getOrDefault("X-Amz-Credential")
  valid_594559 = validateParameter(valid_594559, JString, required = false,
                                 default = nil)
  if valid_594559 != nil:
    section.add "X-Amz-Credential", valid_594559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594561: Call_MergeBranchesByFastForward_594549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Merges two branches using the fast-forward merge strategy.
  ## 
  let valid = call_594561.validator(path, query, header, formData, body)
  let scheme = call_594561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594561.url(scheme.get, call_594561.host, call_594561.base,
                         call_594561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594561, url, valid)

proc call*(call_594562: Call_MergeBranchesByFastForward_594549; body: JsonNode): Recallable =
  ## mergeBranchesByFastForward
  ## Merges two branches using the fast-forward merge strategy.
  ##   body: JObject (required)
  var body_594563 = newJObject()
  if body != nil:
    body_594563 = body
  result = call_594562.call(nil, nil, nil, nil, body_594563)

var mergeBranchesByFastForward* = Call_MergeBranchesByFastForward_594549(
    name: "mergeBranchesByFastForward", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesByFastForward",
    validator: validate_MergeBranchesByFastForward_594550, base: "/",
    url: url_MergeBranchesByFastForward_594551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesBySquash_594564 = ref object of OpenApiRestCall_593437
proc url_MergeBranchesBySquash_594566(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_MergeBranchesBySquash_594565(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Merges two branches using the squash merge strategy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594567 = header.getOrDefault("X-Amz-Date")
  valid_594567 = validateParameter(valid_594567, JString, required = false,
                                 default = nil)
  if valid_594567 != nil:
    section.add "X-Amz-Date", valid_594567
  var valid_594568 = header.getOrDefault("X-Amz-Security-Token")
  valid_594568 = validateParameter(valid_594568, JString, required = false,
                                 default = nil)
  if valid_594568 != nil:
    section.add "X-Amz-Security-Token", valid_594568
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594569 = header.getOrDefault("X-Amz-Target")
  valid_594569 = validateParameter(valid_594569, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesBySquash"))
  if valid_594569 != nil:
    section.add "X-Amz-Target", valid_594569
  var valid_594570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594570 = validateParameter(valid_594570, JString, required = false,
                                 default = nil)
  if valid_594570 != nil:
    section.add "X-Amz-Content-Sha256", valid_594570
  var valid_594571 = header.getOrDefault("X-Amz-Algorithm")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "X-Amz-Algorithm", valid_594571
  var valid_594572 = header.getOrDefault("X-Amz-Signature")
  valid_594572 = validateParameter(valid_594572, JString, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "X-Amz-Signature", valid_594572
  var valid_594573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594573 = validateParameter(valid_594573, JString, required = false,
                                 default = nil)
  if valid_594573 != nil:
    section.add "X-Amz-SignedHeaders", valid_594573
  var valid_594574 = header.getOrDefault("X-Amz-Credential")
  valid_594574 = validateParameter(valid_594574, JString, required = false,
                                 default = nil)
  if valid_594574 != nil:
    section.add "X-Amz-Credential", valid_594574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594576: Call_MergeBranchesBySquash_594564; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Merges two branches using the squash merge strategy.
  ## 
  let valid = call_594576.validator(path, query, header, formData, body)
  let scheme = call_594576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594576.url(scheme.get, call_594576.host, call_594576.base,
                         call_594576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594576, url, valid)

proc call*(call_594577: Call_MergeBranchesBySquash_594564; body: JsonNode): Recallable =
  ## mergeBranchesBySquash
  ## Merges two branches using the squash merge strategy.
  ##   body: JObject (required)
  var body_594578 = newJObject()
  if body != nil:
    body_594578 = body
  result = call_594577.call(nil, nil, nil, nil, body_594578)

var mergeBranchesBySquash* = Call_MergeBranchesBySquash_594564(
    name: "mergeBranchesBySquash", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesBySquash",
    validator: validate_MergeBranchesBySquash_594565, base: "/",
    url: url_MergeBranchesBySquash_594566, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesByThreeWay_594579 = ref object of OpenApiRestCall_593437
proc url_MergeBranchesByThreeWay_594581(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_MergeBranchesByThreeWay_594580(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Merges two specified branches using the three-way merge strategy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594582 = header.getOrDefault("X-Amz-Date")
  valid_594582 = validateParameter(valid_594582, JString, required = false,
                                 default = nil)
  if valid_594582 != nil:
    section.add "X-Amz-Date", valid_594582
  var valid_594583 = header.getOrDefault("X-Amz-Security-Token")
  valid_594583 = validateParameter(valid_594583, JString, required = false,
                                 default = nil)
  if valid_594583 != nil:
    section.add "X-Amz-Security-Token", valid_594583
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594584 = header.getOrDefault("X-Amz-Target")
  valid_594584 = validateParameter(valid_594584, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesByThreeWay"))
  if valid_594584 != nil:
    section.add "X-Amz-Target", valid_594584
  var valid_594585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594585 = validateParameter(valid_594585, JString, required = false,
                                 default = nil)
  if valid_594585 != nil:
    section.add "X-Amz-Content-Sha256", valid_594585
  var valid_594586 = header.getOrDefault("X-Amz-Algorithm")
  valid_594586 = validateParameter(valid_594586, JString, required = false,
                                 default = nil)
  if valid_594586 != nil:
    section.add "X-Amz-Algorithm", valid_594586
  var valid_594587 = header.getOrDefault("X-Amz-Signature")
  valid_594587 = validateParameter(valid_594587, JString, required = false,
                                 default = nil)
  if valid_594587 != nil:
    section.add "X-Amz-Signature", valid_594587
  var valid_594588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594588 = validateParameter(valid_594588, JString, required = false,
                                 default = nil)
  if valid_594588 != nil:
    section.add "X-Amz-SignedHeaders", valid_594588
  var valid_594589 = header.getOrDefault("X-Amz-Credential")
  valid_594589 = validateParameter(valid_594589, JString, required = false,
                                 default = nil)
  if valid_594589 != nil:
    section.add "X-Amz-Credential", valid_594589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594591: Call_MergeBranchesByThreeWay_594579; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Merges two specified branches using the three-way merge strategy.
  ## 
  let valid = call_594591.validator(path, query, header, formData, body)
  let scheme = call_594591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594591.url(scheme.get, call_594591.host, call_594591.base,
                         call_594591.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594591, url, valid)

proc call*(call_594592: Call_MergeBranchesByThreeWay_594579; body: JsonNode): Recallable =
  ## mergeBranchesByThreeWay
  ## Merges two specified branches using the three-way merge strategy.
  ##   body: JObject (required)
  var body_594593 = newJObject()
  if body != nil:
    body_594593 = body
  result = call_594592.call(nil, nil, nil, nil, body_594593)

var mergeBranchesByThreeWay* = Call_MergeBranchesByThreeWay_594579(
    name: "mergeBranchesByThreeWay", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesByThreeWay",
    validator: validate_MergeBranchesByThreeWay_594580, base: "/",
    url: url_MergeBranchesByThreeWay_594581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestByFastForward_594594 = ref object of OpenApiRestCall_593437
proc url_MergePullRequestByFastForward_594596(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_MergePullRequestByFastForward_594595(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the fast-forward merge strategy. If the merge is successful, it closes the pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594597 = header.getOrDefault("X-Amz-Date")
  valid_594597 = validateParameter(valid_594597, JString, required = false,
                                 default = nil)
  if valid_594597 != nil:
    section.add "X-Amz-Date", valid_594597
  var valid_594598 = header.getOrDefault("X-Amz-Security-Token")
  valid_594598 = validateParameter(valid_594598, JString, required = false,
                                 default = nil)
  if valid_594598 != nil:
    section.add "X-Amz-Security-Token", valid_594598
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594599 = header.getOrDefault("X-Amz-Target")
  valid_594599 = validateParameter(valid_594599, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestByFastForward"))
  if valid_594599 != nil:
    section.add "X-Amz-Target", valid_594599
  var valid_594600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594600 = validateParameter(valid_594600, JString, required = false,
                                 default = nil)
  if valid_594600 != nil:
    section.add "X-Amz-Content-Sha256", valid_594600
  var valid_594601 = header.getOrDefault("X-Amz-Algorithm")
  valid_594601 = validateParameter(valid_594601, JString, required = false,
                                 default = nil)
  if valid_594601 != nil:
    section.add "X-Amz-Algorithm", valid_594601
  var valid_594602 = header.getOrDefault("X-Amz-Signature")
  valid_594602 = validateParameter(valid_594602, JString, required = false,
                                 default = nil)
  if valid_594602 != nil:
    section.add "X-Amz-Signature", valid_594602
  var valid_594603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594603 = validateParameter(valid_594603, JString, required = false,
                                 default = nil)
  if valid_594603 != nil:
    section.add "X-Amz-SignedHeaders", valid_594603
  var valid_594604 = header.getOrDefault("X-Amz-Credential")
  valid_594604 = validateParameter(valid_594604, JString, required = false,
                                 default = nil)
  if valid_594604 != nil:
    section.add "X-Amz-Credential", valid_594604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594606: Call_MergePullRequestByFastForward_594594; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the fast-forward merge strategy. If the merge is successful, it closes the pull request.
  ## 
  let valid = call_594606.validator(path, query, header, formData, body)
  let scheme = call_594606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594606.url(scheme.get, call_594606.host, call_594606.base,
                         call_594606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594606, url, valid)

proc call*(call_594607: Call_MergePullRequestByFastForward_594594; body: JsonNode): Recallable =
  ## mergePullRequestByFastForward
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the fast-forward merge strategy. If the merge is successful, it closes the pull request.
  ##   body: JObject (required)
  var body_594608 = newJObject()
  if body != nil:
    body_594608 = body
  result = call_594607.call(nil, nil, nil, nil, body_594608)

var mergePullRequestByFastForward* = Call_MergePullRequestByFastForward_594594(
    name: "mergePullRequestByFastForward", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestByFastForward",
    validator: validate_MergePullRequestByFastForward_594595, base: "/",
    url: url_MergePullRequestByFastForward_594596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestBySquash_594609 = ref object of OpenApiRestCall_593437
proc url_MergePullRequestBySquash_594611(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_MergePullRequestBySquash_594610(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the squash merge strategy. If the merge is successful, it closes the pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594612 = header.getOrDefault("X-Amz-Date")
  valid_594612 = validateParameter(valid_594612, JString, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "X-Amz-Date", valid_594612
  var valid_594613 = header.getOrDefault("X-Amz-Security-Token")
  valid_594613 = validateParameter(valid_594613, JString, required = false,
                                 default = nil)
  if valid_594613 != nil:
    section.add "X-Amz-Security-Token", valid_594613
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594614 = header.getOrDefault("X-Amz-Target")
  valid_594614 = validateParameter(valid_594614, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestBySquash"))
  if valid_594614 != nil:
    section.add "X-Amz-Target", valid_594614
  var valid_594615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594615 = validateParameter(valid_594615, JString, required = false,
                                 default = nil)
  if valid_594615 != nil:
    section.add "X-Amz-Content-Sha256", valid_594615
  var valid_594616 = header.getOrDefault("X-Amz-Algorithm")
  valid_594616 = validateParameter(valid_594616, JString, required = false,
                                 default = nil)
  if valid_594616 != nil:
    section.add "X-Amz-Algorithm", valid_594616
  var valid_594617 = header.getOrDefault("X-Amz-Signature")
  valid_594617 = validateParameter(valid_594617, JString, required = false,
                                 default = nil)
  if valid_594617 != nil:
    section.add "X-Amz-Signature", valid_594617
  var valid_594618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594618 = validateParameter(valid_594618, JString, required = false,
                                 default = nil)
  if valid_594618 != nil:
    section.add "X-Amz-SignedHeaders", valid_594618
  var valid_594619 = header.getOrDefault("X-Amz-Credential")
  valid_594619 = validateParameter(valid_594619, JString, required = false,
                                 default = nil)
  if valid_594619 != nil:
    section.add "X-Amz-Credential", valid_594619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594621: Call_MergePullRequestBySquash_594609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the squash merge strategy. If the merge is successful, it closes the pull request.
  ## 
  let valid = call_594621.validator(path, query, header, formData, body)
  let scheme = call_594621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594621.url(scheme.get, call_594621.host, call_594621.base,
                         call_594621.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594621, url, valid)

proc call*(call_594622: Call_MergePullRequestBySquash_594609; body: JsonNode): Recallable =
  ## mergePullRequestBySquash
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the squash merge strategy. If the merge is successful, it closes the pull request.
  ##   body: JObject (required)
  var body_594623 = newJObject()
  if body != nil:
    body_594623 = body
  result = call_594622.call(nil, nil, nil, nil, body_594623)

var mergePullRequestBySquash* = Call_MergePullRequestBySquash_594609(
    name: "mergePullRequestBySquash", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestBySquash",
    validator: validate_MergePullRequestBySquash_594610, base: "/",
    url: url_MergePullRequestBySquash_594611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestByThreeWay_594624 = ref object of OpenApiRestCall_593437
proc url_MergePullRequestByThreeWay_594626(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_MergePullRequestByThreeWay_594625(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the three-way merge strategy. If the merge is successful, it closes the pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594627 = header.getOrDefault("X-Amz-Date")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-Date", valid_594627
  var valid_594628 = header.getOrDefault("X-Amz-Security-Token")
  valid_594628 = validateParameter(valid_594628, JString, required = false,
                                 default = nil)
  if valid_594628 != nil:
    section.add "X-Amz-Security-Token", valid_594628
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594629 = header.getOrDefault("X-Amz-Target")
  valid_594629 = validateParameter(valid_594629, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestByThreeWay"))
  if valid_594629 != nil:
    section.add "X-Amz-Target", valid_594629
  var valid_594630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594630 = validateParameter(valid_594630, JString, required = false,
                                 default = nil)
  if valid_594630 != nil:
    section.add "X-Amz-Content-Sha256", valid_594630
  var valid_594631 = header.getOrDefault("X-Amz-Algorithm")
  valid_594631 = validateParameter(valid_594631, JString, required = false,
                                 default = nil)
  if valid_594631 != nil:
    section.add "X-Amz-Algorithm", valid_594631
  var valid_594632 = header.getOrDefault("X-Amz-Signature")
  valid_594632 = validateParameter(valid_594632, JString, required = false,
                                 default = nil)
  if valid_594632 != nil:
    section.add "X-Amz-Signature", valid_594632
  var valid_594633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594633 = validateParameter(valid_594633, JString, required = false,
                                 default = nil)
  if valid_594633 != nil:
    section.add "X-Amz-SignedHeaders", valid_594633
  var valid_594634 = header.getOrDefault("X-Amz-Credential")
  valid_594634 = validateParameter(valid_594634, JString, required = false,
                                 default = nil)
  if valid_594634 != nil:
    section.add "X-Amz-Credential", valid_594634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594636: Call_MergePullRequestByThreeWay_594624; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the three-way merge strategy. If the merge is successful, it closes the pull request.
  ## 
  let valid = call_594636.validator(path, query, header, formData, body)
  let scheme = call_594636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594636.url(scheme.get, call_594636.host, call_594636.base,
                         call_594636.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594636, url, valid)

proc call*(call_594637: Call_MergePullRequestByThreeWay_594624; body: JsonNode): Recallable =
  ## mergePullRequestByThreeWay
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the three-way merge strategy. If the merge is successful, it closes the pull request.
  ##   body: JObject (required)
  var body_594638 = newJObject()
  if body != nil:
    body_594638 = body
  result = call_594637.call(nil, nil, nil, nil, body_594638)

var mergePullRequestByThreeWay* = Call_MergePullRequestByThreeWay_594624(
    name: "mergePullRequestByThreeWay", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestByThreeWay",
    validator: validate_MergePullRequestByThreeWay_594625, base: "/",
    url: url_MergePullRequestByThreeWay_594626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentForComparedCommit_594639 = ref object of OpenApiRestCall_593437
proc url_PostCommentForComparedCommit_594641(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCommentForComparedCommit_594640(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Posts a comment on the comparison between two commits.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594642 = header.getOrDefault("X-Amz-Date")
  valid_594642 = validateParameter(valid_594642, JString, required = false,
                                 default = nil)
  if valid_594642 != nil:
    section.add "X-Amz-Date", valid_594642
  var valid_594643 = header.getOrDefault("X-Amz-Security-Token")
  valid_594643 = validateParameter(valid_594643, JString, required = false,
                                 default = nil)
  if valid_594643 != nil:
    section.add "X-Amz-Security-Token", valid_594643
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594644 = header.getOrDefault("X-Amz-Target")
  valid_594644 = validateParameter(valid_594644, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentForComparedCommit"))
  if valid_594644 != nil:
    section.add "X-Amz-Target", valid_594644
  var valid_594645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594645 = validateParameter(valid_594645, JString, required = false,
                                 default = nil)
  if valid_594645 != nil:
    section.add "X-Amz-Content-Sha256", valid_594645
  var valid_594646 = header.getOrDefault("X-Amz-Algorithm")
  valid_594646 = validateParameter(valid_594646, JString, required = false,
                                 default = nil)
  if valid_594646 != nil:
    section.add "X-Amz-Algorithm", valid_594646
  var valid_594647 = header.getOrDefault("X-Amz-Signature")
  valid_594647 = validateParameter(valid_594647, JString, required = false,
                                 default = nil)
  if valid_594647 != nil:
    section.add "X-Amz-Signature", valid_594647
  var valid_594648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594648 = validateParameter(valid_594648, JString, required = false,
                                 default = nil)
  if valid_594648 != nil:
    section.add "X-Amz-SignedHeaders", valid_594648
  var valid_594649 = header.getOrDefault("X-Amz-Credential")
  valid_594649 = validateParameter(valid_594649, JString, required = false,
                                 default = nil)
  if valid_594649 != nil:
    section.add "X-Amz-Credential", valid_594649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594651: Call_PostCommentForComparedCommit_594639; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Posts a comment on the comparison between two commits.
  ## 
  let valid = call_594651.validator(path, query, header, formData, body)
  let scheme = call_594651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594651.url(scheme.get, call_594651.host, call_594651.base,
                         call_594651.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594651, url, valid)

proc call*(call_594652: Call_PostCommentForComparedCommit_594639; body: JsonNode): Recallable =
  ## postCommentForComparedCommit
  ## Posts a comment on the comparison between two commits.
  ##   body: JObject (required)
  var body_594653 = newJObject()
  if body != nil:
    body_594653 = body
  result = call_594652.call(nil, nil, nil, nil, body_594653)

var postCommentForComparedCommit* = Call_PostCommentForComparedCommit_594639(
    name: "postCommentForComparedCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentForComparedCommit",
    validator: validate_PostCommentForComparedCommit_594640, base: "/",
    url: url_PostCommentForComparedCommit_594641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentForPullRequest_594654 = ref object of OpenApiRestCall_593437
proc url_PostCommentForPullRequest_594656(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCommentForPullRequest_594655(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Posts a comment on a pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594657 = header.getOrDefault("X-Amz-Date")
  valid_594657 = validateParameter(valid_594657, JString, required = false,
                                 default = nil)
  if valid_594657 != nil:
    section.add "X-Amz-Date", valid_594657
  var valid_594658 = header.getOrDefault("X-Amz-Security-Token")
  valid_594658 = validateParameter(valid_594658, JString, required = false,
                                 default = nil)
  if valid_594658 != nil:
    section.add "X-Amz-Security-Token", valid_594658
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594659 = header.getOrDefault("X-Amz-Target")
  valid_594659 = validateParameter(valid_594659, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentForPullRequest"))
  if valid_594659 != nil:
    section.add "X-Amz-Target", valid_594659
  var valid_594660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594660 = validateParameter(valid_594660, JString, required = false,
                                 default = nil)
  if valid_594660 != nil:
    section.add "X-Amz-Content-Sha256", valid_594660
  var valid_594661 = header.getOrDefault("X-Amz-Algorithm")
  valid_594661 = validateParameter(valid_594661, JString, required = false,
                                 default = nil)
  if valid_594661 != nil:
    section.add "X-Amz-Algorithm", valid_594661
  var valid_594662 = header.getOrDefault("X-Amz-Signature")
  valid_594662 = validateParameter(valid_594662, JString, required = false,
                                 default = nil)
  if valid_594662 != nil:
    section.add "X-Amz-Signature", valid_594662
  var valid_594663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594663 = validateParameter(valid_594663, JString, required = false,
                                 default = nil)
  if valid_594663 != nil:
    section.add "X-Amz-SignedHeaders", valid_594663
  var valid_594664 = header.getOrDefault("X-Amz-Credential")
  valid_594664 = validateParameter(valid_594664, JString, required = false,
                                 default = nil)
  if valid_594664 != nil:
    section.add "X-Amz-Credential", valid_594664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594666: Call_PostCommentForPullRequest_594654; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Posts a comment on a pull request.
  ## 
  let valid = call_594666.validator(path, query, header, formData, body)
  let scheme = call_594666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594666.url(scheme.get, call_594666.host, call_594666.base,
                         call_594666.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594666, url, valid)

proc call*(call_594667: Call_PostCommentForPullRequest_594654; body: JsonNode): Recallable =
  ## postCommentForPullRequest
  ## Posts a comment on a pull request.
  ##   body: JObject (required)
  var body_594668 = newJObject()
  if body != nil:
    body_594668 = body
  result = call_594667.call(nil, nil, nil, nil, body_594668)

var postCommentForPullRequest* = Call_PostCommentForPullRequest_594654(
    name: "postCommentForPullRequest", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentForPullRequest",
    validator: validate_PostCommentForPullRequest_594655, base: "/",
    url: url_PostCommentForPullRequest_594656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentReply_594669 = ref object of OpenApiRestCall_593437
proc url_PostCommentReply_594671(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCommentReply_594670(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Posts a comment in reply to an existing comment on a comparison between commits or a pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594672 = header.getOrDefault("X-Amz-Date")
  valid_594672 = validateParameter(valid_594672, JString, required = false,
                                 default = nil)
  if valid_594672 != nil:
    section.add "X-Amz-Date", valid_594672
  var valid_594673 = header.getOrDefault("X-Amz-Security-Token")
  valid_594673 = validateParameter(valid_594673, JString, required = false,
                                 default = nil)
  if valid_594673 != nil:
    section.add "X-Amz-Security-Token", valid_594673
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594674 = header.getOrDefault("X-Amz-Target")
  valid_594674 = validateParameter(valid_594674, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentReply"))
  if valid_594674 != nil:
    section.add "X-Amz-Target", valid_594674
  var valid_594675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594675 = validateParameter(valid_594675, JString, required = false,
                                 default = nil)
  if valid_594675 != nil:
    section.add "X-Amz-Content-Sha256", valid_594675
  var valid_594676 = header.getOrDefault("X-Amz-Algorithm")
  valid_594676 = validateParameter(valid_594676, JString, required = false,
                                 default = nil)
  if valid_594676 != nil:
    section.add "X-Amz-Algorithm", valid_594676
  var valid_594677 = header.getOrDefault("X-Amz-Signature")
  valid_594677 = validateParameter(valid_594677, JString, required = false,
                                 default = nil)
  if valid_594677 != nil:
    section.add "X-Amz-Signature", valid_594677
  var valid_594678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594678 = validateParameter(valid_594678, JString, required = false,
                                 default = nil)
  if valid_594678 != nil:
    section.add "X-Amz-SignedHeaders", valid_594678
  var valid_594679 = header.getOrDefault("X-Amz-Credential")
  valid_594679 = validateParameter(valid_594679, JString, required = false,
                                 default = nil)
  if valid_594679 != nil:
    section.add "X-Amz-Credential", valid_594679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594681: Call_PostCommentReply_594669; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Posts a comment in reply to an existing comment on a comparison between commits or a pull request.
  ## 
  let valid = call_594681.validator(path, query, header, formData, body)
  let scheme = call_594681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594681.url(scheme.get, call_594681.host, call_594681.base,
                         call_594681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594681, url, valid)

proc call*(call_594682: Call_PostCommentReply_594669; body: JsonNode): Recallable =
  ## postCommentReply
  ## Posts a comment in reply to an existing comment on a comparison between commits or a pull request.
  ##   body: JObject (required)
  var body_594683 = newJObject()
  if body != nil:
    body_594683 = body
  result = call_594682.call(nil, nil, nil, nil, body_594683)

var postCommentReply* = Call_PostCommentReply_594669(name: "postCommentReply",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentReply",
    validator: validate_PostCommentReply_594670, base: "/",
    url: url_PostCommentReply_594671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFile_594684 = ref object of OpenApiRestCall_593437
proc url_PutFile_594686(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutFile_594685(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds or updates a file in a branch in an AWS CodeCommit repository, and generates a commit for the addition in the specified branch.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594687 = header.getOrDefault("X-Amz-Date")
  valid_594687 = validateParameter(valid_594687, JString, required = false,
                                 default = nil)
  if valid_594687 != nil:
    section.add "X-Amz-Date", valid_594687
  var valid_594688 = header.getOrDefault("X-Amz-Security-Token")
  valid_594688 = validateParameter(valid_594688, JString, required = false,
                                 default = nil)
  if valid_594688 != nil:
    section.add "X-Amz-Security-Token", valid_594688
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594689 = header.getOrDefault("X-Amz-Target")
  valid_594689 = validateParameter(valid_594689, JString, required = true, default = newJString(
      "CodeCommit_20150413.PutFile"))
  if valid_594689 != nil:
    section.add "X-Amz-Target", valid_594689
  var valid_594690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594690 = validateParameter(valid_594690, JString, required = false,
                                 default = nil)
  if valid_594690 != nil:
    section.add "X-Amz-Content-Sha256", valid_594690
  var valid_594691 = header.getOrDefault("X-Amz-Algorithm")
  valid_594691 = validateParameter(valid_594691, JString, required = false,
                                 default = nil)
  if valid_594691 != nil:
    section.add "X-Amz-Algorithm", valid_594691
  var valid_594692 = header.getOrDefault("X-Amz-Signature")
  valid_594692 = validateParameter(valid_594692, JString, required = false,
                                 default = nil)
  if valid_594692 != nil:
    section.add "X-Amz-Signature", valid_594692
  var valid_594693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594693 = validateParameter(valid_594693, JString, required = false,
                                 default = nil)
  if valid_594693 != nil:
    section.add "X-Amz-SignedHeaders", valid_594693
  var valid_594694 = header.getOrDefault("X-Amz-Credential")
  valid_594694 = validateParameter(valid_594694, JString, required = false,
                                 default = nil)
  if valid_594694 != nil:
    section.add "X-Amz-Credential", valid_594694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594696: Call_PutFile_594684; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates a file in a branch in an AWS CodeCommit repository, and generates a commit for the addition in the specified branch.
  ## 
  let valid = call_594696.validator(path, query, header, formData, body)
  let scheme = call_594696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594696.url(scheme.get, call_594696.host, call_594696.base,
                         call_594696.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594696, url, valid)

proc call*(call_594697: Call_PutFile_594684; body: JsonNode): Recallable =
  ## putFile
  ## Adds or updates a file in a branch in an AWS CodeCommit repository, and generates a commit for the addition in the specified branch.
  ##   body: JObject (required)
  var body_594698 = newJObject()
  if body != nil:
    body_594698 = body
  result = call_594697.call(nil, nil, nil, nil, body_594698)

var putFile* = Call_PutFile_594684(name: "putFile", meth: HttpMethod.HttpPost,
                                host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.PutFile",
                                validator: validate_PutFile_594685, base: "/",
                                url: url_PutFile_594686,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRepositoryTriggers_594699 = ref object of OpenApiRestCall_593437
proc url_PutRepositoryTriggers_594701(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutRepositoryTriggers_594700(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Replaces all triggers for a repository. This can be used to create or delete triggers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594702 = header.getOrDefault("X-Amz-Date")
  valid_594702 = validateParameter(valid_594702, JString, required = false,
                                 default = nil)
  if valid_594702 != nil:
    section.add "X-Amz-Date", valid_594702
  var valid_594703 = header.getOrDefault("X-Amz-Security-Token")
  valid_594703 = validateParameter(valid_594703, JString, required = false,
                                 default = nil)
  if valid_594703 != nil:
    section.add "X-Amz-Security-Token", valid_594703
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594704 = header.getOrDefault("X-Amz-Target")
  valid_594704 = validateParameter(valid_594704, JString, required = true, default = newJString(
      "CodeCommit_20150413.PutRepositoryTriggers"))
  if valid_594704 != nil:
    section.add "X-Amz-Target", valid_594704
  var valid_594705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594705 = validateParameter(valid_594705, JString, required = false,
                                 default = nil)
  if valid_594705 != nil:
    section.add "X-Amz-Content-Sha256", valid_594705
  var valid_594706 = header.getOrDefault("X-Amz-Algorithm")
  valid_594706 = validateParameter(valid_594706, JString, required = false,
                                 default = nil)
  if valid_594706 != nil:
    section.add "X-Amz-Algorithm", valid_594706
  var valid_594707 = header.getOrDefault("X-Amz-Signature")
  valid_594707 = validateParameter(valid_594707, JString, required = false,
                                 default = nil)
  if valid_594707 != nil:
    section.add "X-Amz-Signature", valid_594707
  var valid_594708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594708 = validateParameter(valid_594708, JString, required = false,
                                 default = nil)
  if valid_594708 != nil:
    section.add "X-Amz-SignedHeaders", valid_594708
  var valid_594709 = header.getOrDefault("X-Amz-Credential")
  valid_594709 = validateParameter(valid_594709, JString, required = false,
                                 default = nil)
  if valid_594709 != nil:
    section.add "X-Amz-Credential", valid_594709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594711: Call_PutRepositoryTriggers_594699; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces all triggers for a repository. This can be used to create or delete triggers.
  ## 
  let valid = call_594711.validator(path, query, header, formData, body)
  let scheme = call_594711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594711.url(scheme.get, call_594711.host, call_594711.base,
                         call_594711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594711, url, valid)

proc call*(call_594712: Call_PutRepositoryTriggers_594699; body: JsonNode): Recallable =
  ## putRepositoryTriggers
  ## Replaces all triggers for a repository. This can be used to create or delete triggers.
  ##   body: JObject (required)
  var body_594713 = newJObject()
  if body != nil:
    body_594713 = body
  result = call_594712.call(nil, nil, nil, nil, body_594713)

var putRepositoryTriggers* = Call_PutRepositoryTriggers_594699(
    name: "putRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PutRepositoryTriggers",
    validator: validate_PutRepositoryTriggers_594700, base: "/",
    url: url_PutRepositoryTriggers_594701, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594714 = ref object of OpenApiRestCall_593437
proc url_TagResource_594716(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_594715(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds or updates tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594717 = header.getOrDefault("X-Amz-Date")
  valid_594717 = validateParameter(valid_594717, JString, required = false,
                                 default = nil)
  if valid_594717 != nil:
    section.add "X-Amz-Date", valid_594717
  var valid_594718 = header.getOrDefault("X-Amz-Security-Token")
  valid_594718 = validateParameter(valid_594718, JString, required = false,
                                 default = nil)
  if valid_594718 != nil:
    section.add "X-Amz-Security-Token", valid_594718
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594719 = header.getOrDefault("X-Amz-Target")
  valid_594719 = validateParameter(valid_594719, JString, required = true, default = newJString(
      "CodeCommit_20150413.TagResource"))
  if valid_594719 != nil:
    section.add "X-Amz-Target", valid_594719
  var valid_594720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594720 = validateParameter(valid_594720, JString, required = false,
                                 default = nil)
  if valid_594720 != nil:
    section.add "X-Amz-Content-Sha256", valid_594720
  var valid_594721 = header.getOrDefault("X-Amz-Algorithm")
  valid_594721 = validateParameter(valid_594721, JString, required = false,
                                 default = nil)
  if valid_594721 != nil:
    section.add "X-Amz-Algorithm", valid_594721
  var valid_594722 = header.getOrDefault("X-Amz-Signature")
  valid_594722 = validateParameter(valid_594722, JString, required = false,
                                 default = nil)
  if valid_594722 != nil:
    section.add "X-Amz-Signature", valid_594722
  var valid_594723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594723 = validateParameter(valid_594723, JString, required = false,
                                 default = nil)
  if valid_594723 != nil:
    section.add "X-Amz-SignedHeaders", valid_594723
  var valid_594724 = header.getOrDefault("X-Amz-Credential")
  valid_594724 = validateParameter(valid_594724, JString, required = false,
                                 default = nil)
  if valid_594724 != nil:
    section.add "X-Amz-Credential", valid_594724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594726: Call_TagResource_594714; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ## 
  let valid = call_594726.validator(path, query, header, formData, body)
  let scheme = call_594726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594726.url(scheme.get, call_594726.host, call_594726.base,
                         call_594726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594726, url, valid)

proc call*(call_594727: Call_TagResource_594714; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ##   body: JObject (required)
  var body_594728 = newJObject()
  if body != nil:
    body_594728 = body
  result = call_594727.call(nil, nil, nil, nil, body_594728)

var tagResource* = Call_TagResource_594714(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.TagResource",
                                        validator: validate_TagResource_594715,
                                        base: "/", url: url_TagResource_594716,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestRepositoryTriggers_594729 = ref object of OpenApiRestCall_593437
proc url_TestRepositoryTriggers_594731(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TestRepositoryTriggers_594730(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Tests the functionality of repository triggers by sending information to the trigger target. If real data is available in the repository, the test will send data from the last commit. If no data is available, sample data will be generated.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594732 = header.getOrDefault("X-Amz-Date")
  valid_594732 = validateParameter(valid_594732, JString, required = false,
                                 default = nil)
  if valid_594732 != nil:
    section.add "X-Amz-Date", valid_594732
  var valid_594733 = header.getOrDefault("X-Amz-Security-Token")
  valid_594733 = validateParameter(valid_594733, JString, required = false,
                                 default = nil)
  if valid_594733 != nil:
    section.add "X-Amz-Security-Token", valid_594733
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594734 = header.getOrDefault("X-Amz-Target")
  valid_594734 = validateParameter(valid_594734, JString, required = true, default = newJString(
      "CodeCommit_20150413.TestRepositoryTriggers"))
  if valid_594734 != nil:
    section.add "X-Amz-Target", valid_594734
  var valid_594735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594735 = validateParameter(valid_594735, JString, required = false,
                                 default = nil)
  if valid_594735 != nil:
    section.add "X-Amz-Content-Sha256", valid_594735
  var valid_594736 = header.getOrDefault("X-Amz-Algorithm")
  valid_594736 = validateParameter(valid_594736, JString, required = false,
                                 default = nil)
  if valid_594736 != nil:
    section.add "X-Amz-Algorithm", valid_594736
  var valid_594737 = header.getOrDefault("X-Amz-Signature")
  valid_594737 = validateParameter(valid_594737, JString, required = false,
                                 default = nil)
  if valid_594737 != nil:
    section.add "X-Amz-Signature", valid_594737
  var valid_594738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594738 = validateParameter(valid_594738, JString, required = false,
                                 default = nil)
  if valid_594738 != nil:
    section.add "X-Amz-SignedHeaders", valid_594738
  var valid_594739 = header.getOrDefault("X-Amz-Credential")
  valid_594739 = validateParameter(valid_594739, JString, required = false,
                                 default = nil)
  if valid_594739 != nil:
    section.add "X-Amz-Credential", valid_594739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594741: Call_TestRepositoryTriggers_594729; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tests the functionality of repository triggers by sending information to the trigger target. If real data is available in the repository, the test will send data from the last commit. If no data is available, sample data will be generated.
  ## 
  let valid = call_594741.validator(path, query, header, formData, body)
  let scheme = call_594741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594741.url(scheme.get, call_594741.host, call_594741.base,
                         call_594741.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594741, url, valid)

proc call*(call_594742: Call_TestRepositoryTriggers_594729; body: JsonNode): Recallable =
  ## testRepositoryTriggers
  ## Tests the functionality of repository triggers by sending information to the trigger target. If real data is available in the repository, the test will send data from the last commit. If no data is available, sample data will be generated.
  ##   body: JObject (required)
  var body_594743 = newJObject()
  if body != nil:
    body_594743 = body
  result = call_594742.call(nil, nil, nil, nil, body_594743)

var testRepositoryTriggers* = Call_TestRepositoryTriggers_594729(
    name: "testRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.TestRepositoryTriggers",
    validator: validate_TestRepositoryTriggers_594730, base: "/",
    url: url_TestRepositoryTriggers_594731, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594744 = ref object of OpenApiRestCall_593437
proc url_UntagResource_594746(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_594745(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594747 = header.getOrDefault("X-Amz-Date")
  valid_594747 = validateParameter(valid_594747, JString, required = false,
                                 default = nil)
  if valid_594747 != nil:
    section.add "X-Amz-Date", valid_594747
  var valid_594748 = header.getOrDefault("X-Amz-Security-Token")
  valid_594748 = validateParameter(valid_594748, JString, required = false,
                                 default = nil)
  if valid_594748 != nil:
    section.add "X-Amz-Security-Token", valid_594748
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594749 = header.getOrDefault("X-Amz-Target")
  valid_594749 = validateParameter(valid_594749, JString, required = true, default = newJString(
      "CodeCommit_20150413.UntagResource"))
  if valid_594749 != nil:
    section.add "X-Amz-Target", valid_594749
  var valid_594750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594750 = validateParameter(valid_594750, JString, required = false,
                                 default = nil)
  if valid_594750 != nil:
    section.add "X-Amz-Content-Sha256", valid_594750
  var valid_594751 = header.getOrDefault("X-Amz-Algorithm")
  valid_594751 = validateParameter(valid_594751, JString, required = false,
                                 default = nil)
  if valid_594751 != nil:
    section.add "X-Amz-Algorithm", valid_594751
  var valid_594752 = header.getOrDefault("X-Amz-Signature")
  valid_594752 = validateParameter(valid_594752, JString, required = false,
                                 default = nil)
  if valid_594752 != nil:
    section.add "X-Amz-Signature", valid_594752
  var valid_594753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594753 = validateParameter(valid_594753, JString, required = false,
                                 default = nil)
  if valid_594753 != nil:
    section.add "X-Amz-SignedHeaders", valid_594753
  var valid_594754 = header.getOrDefault("X-Amz-Credential")
  valid_594754 = validateParameter(valid_594754, JString, required = false,
                                 default = nil)
  if valid_594754 != nil:
    section.add "X-Amz-Credential", valid_594754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594756: Call_UntagResource_594744; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ## 
  let valid = call_594756.validator(path, query, header, formData, body)
  let scheme = call_594756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594756.url(scheme.get, call_594756.host, call_594756.base,
                         call_594756.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594756, url, valid)

proc call*(call_594757: Call_UntagResource_594744; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ##   body: JObject (required)
  var body_594758 = newJObject()
  if body != nil:
    body_594758 = body
  result = call_594757.call(nil, nil, nil, nil, body_594758)

var untagResource* = Call_UntagResource_594744(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UntagResource",
    validator: validate_UntagResource_594745, base: "/", url: url_UntagResource_594746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateComment_594759 = ref object of OpenApiRestCall_593437
proc url_UpdateComment_594761(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateComment_594760(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Replaces the contents of a comment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594762 = header.getOrDefault("X-Amz-Date")
  valid_594762 = validateParameter(valid_594762, JString, required = false,
                                 default = nil)
  if valid_594762 != nil:
    section.add "X-Amz-Date", valid_594762
  var valid_594763 = header.getOrDefault("X-Amz-Security-Token")
  valid_594763 = validateParameter(valid_594763, JString, required = false,
                                 default = nil)
  if valid_594763 != nil:
    section.add "X-Amz-Security-Token", valid_594763
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594764 = header.getOrDefault("X-Amz-Target")
  valid_594764 = validateParameter(valid_594764, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateComment"))
  if valid_594764 != nil:
    section.add "X-Amz-Target", valid_594764
  var valid_594765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594765 = validateParameter(valid_594765, JString, required = false,
                                 default = nil)
  if valid_594765 != nil:
    section.add "X-Amz-Content-Sha256", valid_594765
  var valid_594766 = header.getOrDefault("X-Amz-Algorithm")
  valid_594766 = validateParameter(valid_594766, JString, required = false,
                                 default = nil)
  if valid_594766 != nil:
    section.add "X-Amz-Algorithm", valid_594766
  var valid_594767 = header.getOrDefault("X-Amz-Signature")
  valid_594767 = validateParameter(valid_594767, JString, required = false,
                                 default = nil)
  if valid_594767 != nil:
    section.add "X-Amz-Signature", valid_594767
  var valid_594768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594768 = validateParameter(valid_594768, JString, required = false,
                                 default = nil)
  if valid_594768 != nil:
    section.add "X-Amz-SignedHeaders", valid_594768
  var valid_594769 = header.getOrDefault("X-Amz-Credential")
  valid_594769 = validateParameter(valid_594769, JString, required = false,
                                 default = nil)
  if valid_594769 != nil:
    section.add "X-Amz-Credential", valid_594769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594771: Call_UpdateComment_594759; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the contents of a comment.
  ## 
  let valid = call_594771.validator(path, query, header, formData, body)
  let scheme = call_594771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594771.url(scheme.get, call_594771.host, call_594771.base,
                         call_594771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594771, url, valid)

proc call*(call_594772: Call_UpdateComment_594759; body: JsonNode): Recallable =
  ## updateComment
  ## Replaces the contents of a comment.
  ##   body: JObject (required)
  var body_594773 = newJObject()
  if body != nil:
    body_594773 = body
  result = call_594772.call(nil, nil, nil, nil, body_594773)

var updateComment* = Call_UpdateComment_594759(name: "updateComment",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateComment",
    validator: validate_UpdateComment_594760, base: "/", url: url_UpdateComment_594761,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDefaultBranch_594774 = ref object of OpenApiRestCall_593437
proc url_UpdateDefaultBranch_594776(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDefaultBranch_594775(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Sets or changes the default branch name for the specified repository.</p> <note> <p>If you use this operation to change the default branch name to the current default branch name, a success message is returned even though the default branch did not change.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594777 = header.getOrDefault("X-Amz-Date")
  valid_594777 = validateParameter(valid_594777, JString, required = false,
                                 default = nil)
  if valid_594777 != nil:
    section.add "X-Amz-Date", valid_594777
  var valid_594778 = header.getOrDefault("X-Amz-Security-Token")
  valid_594778 = validateParameter(valid_594778, JString, required = false,
                                 default = nil)
  if valid_594778 != nil:
    section.add "X-Amz-Security-Token", valid_594778
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594779 = header.getOrDefault("X-Amz-Target")
  valid_594779 = validateParameter(valid_594779, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateDefaultBranch"))
  if valid_594779 != nil:
    section.add "X-Amz-Target", valid_594779
  var valid_594780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594780 = validateParameter(valid_594780, JString, required = false,
                                 default = nil)
  if valid_594780 != nil:
    section.add "X-Amz-Content-Sha256", valid_594780
  var valid_594781 = header.getOrDefault("X-Amz-Algorithm")
  valid_594781 = validateParameter(valid_594781, JString, required = false,
                                 default = nil)
  if valid_594781 != nil:
    section.add "X-Amz-Algorithm", valid_594781
  var valid_594782 = header.getOrDefault("X-Amz-Signature")
  valid_594782 = validateParameter(valid_594782, JString, required = false,
                                 default = nil)
  if valid_594782 != nil:
    section.add "X-Amz-Signature", valid_594782
  var valid_594783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594783 = validateParameter(valid_594783, JString, required = false,
                                 default = nil)
  if valid_594783 != nil:
    section.add "X-Amz-SignedHeaders", valid_594783
  var valid_594784 = header.getOrDefault("X-Amz-Credential")
  valid_594784 = validateParameter(valid_594784, JString, required = false,
                                 default = nil)
  if valid_594784 != nil:
    section.add "X-Amz-Credential", valid_594784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594786: Call_UpdateDefaultBranch_594774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or changes the default branch name for the specified repository.</p> <note> <p>If you use this operation to change the default branch name to the current default branch name, a success message is returned even though the default branch did not change.</p> </note>
  ## 
  let valid = call_594786.validator(path, query, header, formData, body)
  let scheme = call_594786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594786.url(scheme.get, call_594786.host, call_594786.base,
                         call_594786.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594786, url, valid)

proc call*(call_594787: Call_UpdateDefaultBranch_594774; body: JsonNode): Recallable =
  ## updateDefaultBranch
  ## <p>Sets or changes the default branch name for the specified repository.</p> <note> <p>If you use this operation to change the default branch name to the current default branch name, a success message is returned even though the default branch did not change.</p> </note>
  ##   body: JObject (required)
  var body_594788 = newJObject()
  if body != nil:
    body_594788 = body
  result = call_594787.call(nil, nil, nil, nil, body_594788)

var updateDefaultBranch* = Call_UpdateDefaultBranch_594774(
    name: "updateDefaultBranch", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateDefaultBranch",
    validator: validate_UpdateDefaultBranch_594775, base: "/",
    url: url_UpdateDefaultBranch_594776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestDescription_594789 = ref object of OpenApiRestCall_593437
proc url_UpdatePullRequestDescription_594791(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdatePullRequestDescription_594790(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Replaces the contents of the description of a pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594792 = header.getOrDefault("X-Amz-Date")
  valid_594792 = validateParameter(valid_594792, JString, required = false,
                                 default = nil)
  if valid_594792 != nil:
    section.add "X-Amz-Date", valid_594792
  var valid_594793 = header.getOrDefault("X-Amz-Security-Token")
  valid_594793 = validateParameter(valid_594793, JString, required = false,
                                 default = nil)
  if valid_594793 != nil:
    section.add "X-Amz-Security-Token", valid_594793
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594794 = header.getOrDefault("X-Amz-Target")
  valid_594794 = validateParameter(valid_594794, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestDescription"))
  if valid_594794 != nil:
    section.add "X-Amz-Target", valid_594794
  var valid_594795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594795 = validateParameter(valid_594795, JString, required = false,
                                 default = nil)
  if valid_594795 != nil:
    section.add "X-Amz-Content-Sha256", valid_594795
  var valid_594796 = header.getOrDefault("X-Amz-Algorithm")
  valid_594796 = validateParameter(valid_594796, JString, required = false,
                                 default = nil)
  if valid_594796 != nil:
    section.add "X-Amz-Algorithm", valid_594796
  var valid_594797 = header.getOrDefault("X-Amz-Signature")
  valid_594797 = validateParameter(valid_594797, JString, required = false,
                                 default = nil)
  if valid_594797 != nil:
    section.add "X-Amz-Signature", valid_594797
  var valid_594798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594798 = validateParameter(valid_594798, JString, required = false,
                                 default = nil)
  if valid_594798 != nil:
    section.add "X-Amz-SignedHeaders", valid_594798
  var valid_594799 = header.getOrDefault("X-Amz-Credential")
  valid_594799 = validateParameter(valid_594799, JString, required = false,
                                 default = nil)
  if valid_594799 != nil:
    section.add "X-Amz-Credential", valid_594799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594801: Call_UpdatePullRequestDescription_594789; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the contents of the description of a pull request.
  ## 
  let valid = call_594801.validator(path, query, header, formData, body)
  let scheme = call_594801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594801.url(scheme.get, call_594801.host, call_594801.base,
                         call_594801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594801, url, valid)

proc call*(call_594802: Call_UpdatePullRequestDescription_594789; body: JsonNode): Recallable =
  ## updatePullRequestDescription
  ## Replaces the contents of the description of a pull request.
  ##   body: JObject (required)
  var body_594803 = newJObject()
  if body != nil:
    body_594803 = body
  result = call_594802.call(nil, nil, nil, nil, body_594803)

var updatePullRequestDescription* = Call_UpdatePullRequestDescription_594789(
    name: "updatePullRequestDescription", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestDescription",
    validator: validate_UpdatePullRequestDescription_594790, base: "/",
    url: url_UpdatePullRequestDescription_594791,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestStatus_594804 = ref object of OpenApiRestCall_593437
proc url_UpdatePullRequestStatus_594806(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdatePullRequestStatus_594805(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the status of a pull request. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594807 = header.getOrDefault("X-Amz-Date")
  valid_594807 = validateParameter(valid_594807, JString, required = false,
                                 default = nil)
  if valid_594807 != nil:
    section.add "X-Amz-Date", valid_594807
  var valid_594808 = header.getOrDefault("X-Amz-Security-Token")
  valid_594808 = validateParameter(valid_594808, JString, required = false,
                                 default = nil)
  if valid_594808 != nil:
    section.add "X-Amz-Security-Token", valid_594808
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594809 = header.getOrDefault("X-Amz-Target")
  valid_594809 = validateParameter(valid_594809, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestStatus"))
  if valid_594809 != nil:
    section.add "X-Amz-Target", valid_594809
  var valid_594810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594810 = validateParameter(valid_594810, JString, required = false,
                                 default = nil)
  if valid_594810 != nil:
    section.add "X-Amz-Content-Sha256", valid_594810
  var valid_594811 = header.getOrDefault("X-Amz-Algorithm")
  valid_594811 = validateParameter(valid_594811, JString, required = false,
                                 default = nil)
  if valid_594811 != nil:
    section.add "X-Amz-Algorithm", valid_594811
  var valid_594812 = header.getOrDefault("X-Amz-Signature")
  valid_594812 = validateParameter(valid_594812, JString, required = false,
                                 default = nil)
  if valid_594812 != nil:
    section.add "X-Amz-Signature", valid_594812
  var valid_594813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594813 = validateParameter(valid_594813, JString, required = false,
                                 default = nil)
  if valid_594813 != nil:
    section.add "X-Amz-SignedHeaders", valid_594813
  var valid_594814 = header.getOrDefault("X-Amz-Credential")
  valid_594814 = validateParameter(valid_594814, JString, required = false,
                                 default = nil)
  if valid_594814 != nil:
    section.add "X-Amz-Credential", valid_594814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594816: Call_UpdatePullRequestStatus_594804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of a pull request. 
  ## 
  let valid = call_594816.validator(path, query, header, formData, body)
  let scheme = call_594816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594816.url(scheme.get, call_594816.host, call_594816.base,
                         call_594816.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594816, url, valid)

proc call*(call_594817: Call_UpdatePullRequestStatus_594804; body: JsonNode): Recallable =
  ## updatePullRequestStatus
  ## Updates the status of a pull request. 
  ##   body: JObject (required)
  var body_594818 = newJObject()
  if body != nil:
    body_594818 = body
  result = call_594817.call(nil, nil, nil, nil, body_594818)

var updatePullRequestStatus* = Call_UpdatePullRequestStatus_594804(
    name: "updatePullRequestStatus", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestStatus",
    validator: validate_UpdatePullRequestStatus_594805, base: "/",
    url: url_UpdatePullRequestStatus_594806, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestTitle_594819 = ref object of OpenApiRestCall_593437
proc url_UpdatePullRequestTitle_594821(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdatePullRequestTitle_594820(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Replaces the title of a pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594822 = header.getOrDefault("X-Amz-Date")
  valid_594822 = validateParameter(valid_594822, JString, required = false,
                                 default = nil)
  if valid_594822 != nil:
    section.add "X-Amz-Date", valid_594822
  var valid_594823 = header.getOrDefault("X-Amz-Security-Token")
  valid_594823 = validateParameter(valid_594823, JString, required = false,
                                 default = nil)
  if valid_594823 != nil:
    section.add "X-Amz-Security-Token", valid_594823
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594824 = header.getOrDefault("X-Amz-Target")
  valid_594824 = validateParameter(valid_594824, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestTitle"))
  if valid_594824 != nil:
    section.add "X-Amz-Target", valid_594824
  var valid_594825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594825 = validateParameter(valid_594825, JString, required = false,
                                 default = nil)
  if valid_594825 != nil:
    section.add "X-Amz-Content-Sha256", valid_594825
  var valid_594826 = header.getOrDefault("X-Amz-Algorithm")
  valid_594826 = validateParameter(valid_594826, JString, required = false,
                                 default = nil)
  if valid_594826 != nil:
    section.add "X-Amz-Algorithm", valid_594826
  var valid_594827 = header.getOrDefault("X-Amz-Signature")
  valid_594827 = validateParameter(valid_594827, JString, required = false,
                                 default = nil)
  if valid_594827 != nil:
    section.add "X-Amz-Signature", valid_594827
  var valid_594828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594828 = validateParameter(valid_594828, JString, required = false,
                                 default = nil)
  if valid_594828 != nil:
    section.add "X-Amz-SignedHeaders", valid_594828
  var valid_594829 = header.getOrDefault("X-Amz-Credential")
  valid_594829 = validateParameter(valid_594829, JString, required = false,
                                 default = nil)
  if valid_594829 != nil:
    section.add "X-Amz-Credential", valid_594829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594831: Call_UpdatePullRequestTitle_594819; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the title of a pull request.
  ## 
  let valid = call_594831.validator(path, query, header, formData, body)
  let scheme = call_594831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594831.url(scheme.get, call_594831.host, call_594831.base,
                         call_594831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594831, url, valid)

proc call*(call_594832: Call_UpdatePullRequestTitle_594819; body: JsonNode): Recallable =
  ## updatePullRequestTitle
  ## Replaces the title of a pull request.
  ##   body: JObject (required)
  var body_594833 = newJObject()
  if body != nil:
    body_594833 = body
  result = call_594832.call(nil, nil, nil, nil, body_594833)

var updatePullRequestTitle* = Call_UpdatePullRequestTitle_594819(
    name: "updatePullRequestTitle", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestTitle",
    validator: validate_UpdatePullRequestTitle_594820, base: "/",
    url: url_UpdatePullRequestTitle_594821, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRepositoryDescription_594834 = ref object of OpenApiRestCall_593437
proc url_UpdateRepositoryDescription_594836(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRepositoryDescription_594835(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets or changes the comment or description for a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594837 = header.getOrDefault("X-Amz-Date")
  valid_594837 = validateParameter(valid_594837, JString, required = false,
                                 default = nil)
  if valid_594837 != nil:
    section.add "X-Amz-Date", valid_594837
  var valid_594838 = header.getOrDefault("X-Amz-Security-Token")
  valid_594838 = validateParameter(valid_594838, JString, required = false,
                                 default = nil)
  if valid_594838 != nil:
    section.add "X-Amz-Security-Token", valid_594838
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594839 = header.getOrDefault("X-Amz-Target")
  valid_594839 = validateParameter(valid_594839, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateRepositoryDescription"))
  if valid_594839 != nil:
    section.add "X-Amz-Target", valid_594839
  var valid_594840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594840 = validateParameter(valid_594840, JString, required = false,
                                 default = nil)
  if valid_594840 != nil:
    section.add "X-Amz-Content-Sha256", valid_594840
  var valid_594841 = header.getOrDefault("X-Amz-Algorithm")
  valid_594841 = validateParameter(valid_594841, JString, required = false,
                                 default = nil)
  if valid_594841 != nil:
    section.add "X-Amz-Algorithm", valid_594841
  var valid_594842 = header.getOrDefault("X-Amz-Signature")
  valid_594842 = validateParameter(valid_594842, JString, required = false,
                                 default = nil)
  if valid_594842 != nil:
    section.add "X-Amz-Signature", valid_594842
  var valid_594843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594843 = validateParameter(valid_594843, JString, required = false,
                                 default = nil)
  if valid_594843 != nil:
    section.add "X-Amz-SignedHeaders", valid_594843
  var valid_594844 = header.getOrDefault("X-Amz-Credential")
  valid_594844 = validateParameter(valid_594844, JString, required = false,
                                 default = nil)
  if valid_594844 != nil:
    section.add "X-Amz-Credential", valid_594844
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594846: Call_UpdateRepositoryDescription_594834; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or changes the comment or description for a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ## 
  let valid = call_594846.validator(path, query, header, formData, body)
  let scheme = call_594846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594846.url(scheme.get, call_594846.host, call_594846.base,
                         call_594846.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594846, url, valid)

proc call*(call_594847: Call_UpdateRepositoryDescription_594834; body: JsonNode): Recallable =
  ## updateRepositoryDescription
  ## <p>Sets or changes the comment or description for a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ##   body: JObject (required)
  var body_594848 = newJObject()
  if body != nil:
    body_594848 = body
  result = call_594847.call(nil, nil, nil, nil, body_594848)

var updateRepositoryDescription* = Call_UpdateRepositoryDescription_594834(
    name: "updateRepositoryDescription", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateRepositoryDescription",
    validator: validate_UpdateRepositoryDescription_594835, base: "/",
    url: url_UpdateRepositoryDescription_594836,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRepositoryName_594849 = ref object of OpenApiRestCall_593437
proc url_UpdateRepositoryName_594851(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRepositoryName_594850(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Renames a repository. The repository name must be unique across the calling AWS account. In addition, repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. The suffix ".git" is prohibited. For a full description of the limits on repository names, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html">Limits</a> in the AWS CodeCommit User Guide.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594852 = header.getOrDefault("X-Amz-Date")
  valid_594852 = validateParameter(valid_594852, JString, required = false,
                                 default = nil)
  if valid_594852 != nil:
    section.add "X-Amz-Date", valid_594852
  var valid_594853 = header.getOrDefault("X-Amz-Security-Token")
  valid_594853 = validateParameter(valid_594853, JString, required = false,
                                 default = nil)
  if valid_594853 != nil:
    section.add "X-Amz-Security-Token", valid_594853
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594854 = header.getOrDefault("X-Amz-Target")
  valid_594854 = validateParameter(valid_594854, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateRepositoryName"))
  if valid_594854 != nil:
    section.add "X-Amz-Target", valid_594854
  var valid_594855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594855 = validateParameter(valid_594855, JString, required = false,
                                 default = nil)
  if valid_594855 != nil:
    section.add "X-Amz-Content-Sha256", valid_594855
  var valid_594856 = header.getOrDefault("X-Amz-Algorithm")
  valid_594856 = validateParameter(valid_594856, JString, required = false,
                                 default = nil)
  if valid_594856 != nil:
    section.add "X-Amz-Algorithm", valid_594856
  var valid_594857 = header.getOrDefault("X-Amz-Signature")
  valid_594857 = validateParameter(valid_594857, JString, required = false,
                                 default = nil)
  if valid_594857 != nil:
    section.add "X-Amz-Signature", valid_594857
  var valid_594858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594858 = validateParameter(valid_594858, JString, required = false,
                                 default = nil)
  if valid_594858 != nil:
    section.add "X-Amz-SignedHeaders", valid_594858
  var valid_594859 = header.getOrDefault("X-Amz-Credential")
  valid_594859 = validateParameter(valid_594859, JString, required = false,
                                 default = nil)
  if valid_594859 != nil:
    section.add "X-Amz-Credential", valid_594859
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594861: Call_UpdateRepositoryName_594849; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Renames a repository. The repository name must be unique across the calling AWS account. In addition, repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. The suffix ".git" is prohibited. For a full description of the limits on repository names, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html">Limits</a> in the AWS CodeCommit User Guide.
  ## 
  let valid = call_594861.validator(path, query, header, formData, body)
  let scheme = call_594861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594861.url(scheme.get, call_594861.host, call_594861.base,
                         call_594861.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594861, url, valid)

proc call*(call_594862: Call_UpdateRepositoryName_594849; body: JsonNode): Recallable =
  ## updateRepositoryName
  ## Renames a repository. The repository name must be unique across the calling AWS account. In addition, repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. The suffix ".git" is prohibited. For a full description of the limits on repository names, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html">Limits</a> in the AWS CodeCommit User Guide.
  ##   body: JObject (required)
  var body_594863 = newJObject()
  if body != nil:
    body_594863 = body
  result = call_594862.call(nil, nil, nil, nil, body_594863)

var updateRepositoryName* = Call_UpdateRepositoryName_594849(
    name: "updateRepositoryName", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateRepositoryName",
    validator: validate_UpdateRepositoryName_594850, base: "/",
    url: url_UpdateRepositoryName_594851, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
