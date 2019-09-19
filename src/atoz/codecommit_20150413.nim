
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_BatchDescribeMergeConflicts_600768 = ref object of OpenApiRestCall_600426
proc url_BatchDescribeMergeConflicts_600770(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchDescribeMergeConflicts_600769(path: JsonNode; query: JsonNode;
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
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600897 = header.getOrDefault("X-Amz-Target")
  valid_600897 = validateParameter(valid_600897, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchDescribeMergeConflicts"))
  if valid_600897 != nil:
    section.add "X-Amz-Target", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Content-Sha256", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Algorithm")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Algorithm", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Signature")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Signature", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-SignedHeaders", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Credential")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Credential", valid_600902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_BatchDescribeMergeConflicts_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy.
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"))
  result = hook(call_600926, url, valid)

proc call*(call_600997: Call_BatchDescribeMergeConflicts_600768; body: JsonNode): Recallable =
  ## batchDescribeMergeConflicts
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy.
  ##   body: JObject (required)
  var body_600998 = newJObject()
  if body != nil:
    body_600998 = body
  result = call_600997.call(nil, nil, nil, nil, body_600998)

var batchDescribeMergeConflicts* = Call_BatchDescribeMergeConflicts_600768(
    name: "batchDescribeMergeConflicts", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchDescribeMergeConflicts",
    validator: validate_BatchDescribeMergeConflicts_600769, base: "/",
    url: url_BatchDescribeMergeConflicts_600770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetCommits_601037 = ref object of OpenApiRestCall_600426
proc url_BatchGetCommits_601039(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetCommits_601038(path: JsonNode; query: JsonNode;
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
  var valid_601040 = header.getOrDefault("X-Amz-Date")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Date", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Security-Token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Security-Token", valid_601041
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601042 = header.getOrDefault("X-Amz-Target")
  valid_601042 = validateParameter(valid_601042, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchGetCommits"))
  if valid_601042 != nil:
    section.add "X-Amz-Target", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Content-Sha256", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Algorithm")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Algorithm", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Signature")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Signature", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-SignedHeaders", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Credential")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Credential", valid_601047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601049: Call_BatchGetCommits_601037; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the contents of one or more commits in a repository.
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"))
  result = hook(call_601049, url, valid)

proc call*(call_601050: Call_BatchGetCommits_601037; body: JsonNode): Recallable =
  ## batchGetCommits
  ## Returns information about the contents of one or more commits in a repository.
  ##   body: JObject (required)
  var body_601051 = newJObject()
  if body != nil:
    body_601051 = body
  result = call_601050.call(nil, nil, nil, nil, body_601051)

var batchGetCommits* = Call_BatchGetCommits_601037(name: "batchGetCommits",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchGetCommits",
    validator: validate_BatchGetCommits_601038, base: "/", url: url_BatchGetCommits_601039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetRepositories_601052 = ref object of OpenApiRestCall_600426
proc url_BatchGetRepositories_601054(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetRepositories_601053(path: JsonNode; query: JsonNode;
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
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601057 = header.getOrDefault("X-Amz-Target")
  valid_601057 = validateParameter(valid_601057, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchGetRepositories"))
  if valid_601057 != nil:
    section.add "X-Amz-Target", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601064: Call_BatchGetRepositories_601052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about one or more repositories.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ## 
  let valid = call_601064.validator(path, query, header, formData, body)
  let scheme = call_601064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601064.url(scheme.get, call_601064.host, call_601064.base,
                         call_601064.route, valid.getOrDefault("path"))
  result = hook(call_601064, url, valid)

proc call*(call_601065: Call_BatchGetRepositories_601052; body: JsonNode): Recallable =
  ## batchGetRepositories
  ## <p>Returns information about one or more repositories.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ##   body: JObject (required)
  var body_601066 = newJObject()
  if body != nil:
    body_601066 = body
  result = call_601065.call(nil, nil, nil, nil, body_601066)

var batchGetRepositories* = Call_BatchGetRepositories_601052(
    name: "batchGetRepositories", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchGetRepositories",
    validator: validate_BatchGetRepositories_601053, base: "/",
    url: url_BatchGetRepositories_601054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBranch_601067 = ref object of OpenApiRestCall_600426
proc url_CreateBranch_601069(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateBranch_601068(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601070 = header.getOrDefault("X-Amz-Date")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Date", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Security-Token")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Security-Token", valid_601071
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601072 = header.getOrDefault("X-Amz-Target")
  valid_601072 = validateParameter(valid_601072, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateBranch"))
  if valid_601072 != nil:
    section.add "X-Amz-Target", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Content-Sha256", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Algorithm")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Algorithm", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Signature")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Signature", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-SignedHeaders", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Credential")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Credential", valid_601077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601079: Call_CreateBranch_601067; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new branch in a repository and points the branch to a commit.</p> <note> <p>Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.</p> </note>
  ## 
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"))
  result = hook(call_601079, url, valid)

proc call*(call_601080: Call_CreateBranch_601067; body: JsonNode): Recallable =
  ## createBranch
  ## <p>Creates a new branch in a repository and points the branch to a commit.</p> <note> <p>Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.</p> </note>
  ##   body: JObject (required)
  var body_601081 = newJObject()
  if body != nil:
    body_601081 = body
  result = call_601080.call(nil, nil, nil, nil, body_601081)

var createBranch* = Call_CreateBranch_601067(name: "createBranch",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateBranch",
    validator: validate_CreateBranch_601068, base: "/", url: url_CreateBranch_601069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCommit_601082 = ref object of OpenApiRestCall_600426
proc url_CreateCommit_601084(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateCommit_601083(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601085 = header.getOrDefault("X-Amz-Date")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Date", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Security-Token")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Security-Token", valid_601086
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601087 = header.getOrDefault("X-Amz-Target")
  valid_601087 = validateParameter(valid_601087, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateCommit"))
  if valid_601087 != nil:
    section.add "X-Amz-Target", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Content-Sha256", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Algorithm")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Algorithm", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Signature")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Signature", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-SignedHeaders", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Credential")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Credential", valid_601092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601094: Call_CreateCommit_601082; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a commit for a repository on the tip of a specified branch.
  ## 
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"))
  result = hook(call_601094, url, valid)

proc call*(call_601095: Call_CreateCommit_601082; body: JsonNode): Recallable =
  ## createCommit
  ## Creates a commit for a repository on the tip of a specified branch.
  ##   body: JObject (required)
  var body_601096 = newJObject()
  if body != nil:
    body_601096 = body
  result = call_601095.call(nil, nil, nil, nil, body_601096)

var createCommit* = Call_CreateCommit_601082(name: "createCommit",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateCommit",
    validator: validate_CreateCommit_601083, base: "/", url: url_CreateCommit_601084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePullRequest_601097 = ref object of OpenApiRestCall_600426
proc url_CreatePullRequest_601099(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePullRequest_601098(path: JsonNode; query: JsonNode;
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
  var valid_601100 = header.getOrDefault("X-Amz-Date")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Date", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Security-Token")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Security-Token", valid_601101
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601102 = header.getOrDefault("X-Amz-Target")
  valid_601102 = validateParameter(valid_601102, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreatePullRequest"))
  if valid_601102 != nil:
    section.add "X-Amz-Target", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Content-Sha256", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Algorithm")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Algorithm", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Signature")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Signature", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-SignedHeaders", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Credential")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Credential", valid_601107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601109: Call_CreatePullRequest_601097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a pull request in the specified repository.
  ## 
  let valid = call_601109.validator(path, query, header, formData, body)
  let scheme = call_601109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601109.url(scheme.get, call_601109.host, call_601109.base,
                         call_601109.route, valid.getOrDefault("path"))
  result = hook(call_601109, url, valid)

proc call*(call_601110: Call_CreatePullRequest_601097; body: JsonNode): Recallable =
  ## createPullRequest
  ## Creates a pull request in the specified repository.
  ##   body: JObject (required)
  var body_601111 = newJObject()
  if body != nil:
    body_601111 = body
  result = call_601110.call(nil, nil, nil, nil, body_601111)

var createPullRequest* = Call_CreatePullRequest_601097(name: "createPullRequest",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreatePullRequest",
    validator: validate_CreatePullRequest_601098, base: "/",
    url: url_CreatePullRequest_601099, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRepository_601112 = ref object of OpenApiRestCall_600426
proc url_CreateRepository_601114(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateRepository_601113(path: JsonNode; query: JsonNode;
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
  var valid_601115 = header.getOrDefault("X-Amz-Date")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Date", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Security-Token")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Security-Token", valid_601116
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601117 = header.getOrDefault("X-Amz-Target")
  valid_601117 = validateParameter(valid_601117, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateRepository"))
  if valid_601117 != nil:
    section.add "X-Amz-Target", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Content-Sha256", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Algorithm")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Algorithm", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Signature")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Signature", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-SignedHeaders", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Credential")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Credential", valid_601122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601124: Call_CreateRepository_601112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new, empty repository.
  ## 
  let valid = call_601124.validator(path, query, header, formData, body)
  let scheme = call_601124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601124.url(scheme.get, call_601124.host, call_601124.base,
                         call_601124.route, valid.getOrDefault("path"))
  result = hook(call_601124, url, valid)

proc call*(call_601125: Call_CreateRepository_601112; body: JsonNode): Recallable =
  ## createRepository
  ## Creates a new, empty repository.
  ##   body: JObject (required)
  var body_601126 = newJObject()
  if body != nil:
    body_601126 = body
  result = call_601125.call(nil, nil, nil, nil, body_601126)

var createRepository* = Call_CreateRepository_601112(name: "createRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateRepository",
    validator: validate_CreateRepository_601113, base: "/",
    url: url_CreateRepository_601114, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUnreferencedMergeCommit_601127 = ref object of OpenApiRestCall_600426
proc url_CreateUnreferencedMergeCommit_601129(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateUnreferencedMergeCommit_601128(path: JsonNode; query: JsonNode;
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
  var valid_601130 = header.getOrDefault("X-Amz-Date")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Date", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Security-Token")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Security-Token", valid_601131
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601132 = header.getOrDefault("X-Amz-Target")
  valid_601132 = validateParameter(valid_601132, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateUnreferencedMergeCommit"))
  if valid_601132 != nil:
    section.add "X-Amz-Target", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Content-Sha256", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Algorithm")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Algorithm", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Signature")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Signature", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-SignedHeaders", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Credential")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Credential", valid_601137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601139: Call_CreateUnreferencedMergeCommit_601127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an unreferenced commit that represents the result of merging two branches using a specified merge strategy. This can help you determine the outcome of a potential merge. This API cannot be used with the fast-forward merge strategy, as that strategy does not create a merge commit.</p> <note> <p>This unreferenced merge commit can only be accessed using the GetCommit API or through git commands such as git fetch. To retrieve this commit, you must specify its commit ID or otherwise reference it.</p> </note>
  ## 
  let valid = call_601139.validator(path, query, header, formData, body)
  let scheme = call_601139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601139.url(scheme.get, call_601139.host, call_601139.base,
                         call_601139.route, valid.getOrDefault("path"))
  result = hook(call_601139, url, valid)

proc call*(call_601140: Call_CreateUnreferencedMergeCommit_601127; body: JsonNode): Recallable =
  ## createUnreferencedMergeCommit
  ## <p>Creates an unreferenced commit that represents the result of merging two branches using a specified merge strategy. This can help you determine the outcome of a potential merge. This API cannot be used with the fast-forward merge strategy, as that strategy does not create a merge commit.</p> <note> <p>This unreferenced merge commit can only be accessed using the GetCommit API or through git commands such as git fetch. To retrieve this commit, you must specify its commit ID or otherwise reference it.</p> </note>
  ##   body: JObject (required)
  var body_601141 = newJObject()
  if body != nil:
    body_601141 = body
  result = call_601140.call(nil, nil, nil, nil, body_601141)

var createUnreferencedMergeCommit* = Call_CreateUnreferencedMergeCommit_601127(
    name: "createUnreferencedMergeCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateUnreferencedMergeCommit",
    validator: validate_CreateUnreferencedMergeCommit_601128, base: "/",
    url: url_CreateUnreferencedMergeCommit_601129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBranch_601142 = ref object of OpenApiRestCall_600426
proc url_DeleteBranch_601144(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteBranch_601143(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601145 = header.getOrDefault("X-Amz-Date")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Date", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Security-Token")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Security-Token", valid_601146
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601147 = header.getOrDefault("X-Amz-Target")
  valid_601147 = validateParameter(valid_601147, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteBranch"))
  if valid_601147 != nil:
    section.add "X-Amz-Target", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Content-Sha256", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Algorithm")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Algorithm", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Signature")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Signature", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-SignedHeaders", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Credential")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Credential", valid_601152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601154: Call_DeleteBranch_601142; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a branch from a repository, unless that branch is the default branch for the repository. 
  ## 
  let valid = call_601154.validator(path, query, header, formData, body)
  let scheme = call_601154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601154.url(scheme.get, call_601154.host, call_601154.base,
                         call_601154.route, valid.getOrDefault("path"))
  result = hook(call_601154, url, valid)

proc call*(call_601155: Call_DeleteBranch_601142; body: JsonNode): Recallable =
  ## deleteBranch
  ## Deletes a branch from a repository, unless that branch is the default branch for the repository. 
  ##   body: JObject (required)
  var body_601156 = newJObject()
  if body != nil:
    body_601156 = body
  result = call_601155.call(nil, nil, nil, nil, body_601156)

var deleteBranch* = Call_DeleteBranch_601142(name: "deleteBranch",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteBranch",
    validator: validate_DeleteBranch_601143, base: "/", url: url_DeleteBranch_601144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCommentContent_601157 = ref object of OpenApiRestCall_600426
proc url_DeleteCommentContent_601159(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteCommentContent_601158(path: JsonNode; query: JsonNode;
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
  var valid_601160 = header.getOrDefault("X-Amz-Date")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Date", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Security-Token")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Security-Token", valid_601161
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601162 = header.getOrDefault("X-Amz-Target")
  valid_601162 = validateParameter(valid_601162, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteCommentContent"))
  if valid_601162 != nil:
    section.add "X-Amz-Target", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Content-Sha256", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Algorithm")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Algorithm", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Signature")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Signature", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-SignedHeaders", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Credential")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Credential", valid_601167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601169: Call_DeleteCommentContent_601157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the content of a comment made on a change, file, or commit in a repository.
  ## 
  let valid = call_601169.validator(path, query, header, formData, body)
  let scheme = call_601169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601169.url(scheme.get, call_601169.host, call_601169.base,
                         call_601169.route, valid.getOrDefault("path"))
  result = hook(call_601169, url, valid)

proc call*(call_601170: Call_DeleteCommentContent_601157; body: JsonNode): Recallable =
  ## deleteCommentContent
  ## Deletes the content of a comment made on a change, file, or commit in a repository.
  ##   body: JObject (required)
  var body_601171 = newJObject()
  if body != nil:
    body_601171 = body
  result = call_601170.call(nil, nil, nil, nil, body_601171)

var deleteCommentContent* = Call_DeleteCommentContent_601157(
    name: "deleteCommentContent", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteCommentContent",
    validator: validate_DeleteCommentContent_601158, base: "/",
    url: url_DeleteCommentContent_601159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFile_601172 = ref object of OpenApiRestCall_600426
proc url_DeleteFile_601174(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteFile_601173(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601175 = header.getOrDefault("X-Amz-Date")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Date", valid_601175
  var valid_601176 = header.getOrDefault("X-Amz-Security-Token")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Security-Token", valid_601176
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601177 = header.getOrDefault("X-Amz-Target")
  valid_601177 = validateParameter(valid_601177, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteFile"))
  if valid_601177 != nil:
    section.add "X-Amz-Target", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Content-Sha256", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Algorithm")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Algorithm", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Signature")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Signature", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-SignedHeaders", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Credential")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Credential", valid_601182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601184: Call_DeleteFile_601172; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified file from a specified branch. A commit is created on the branch that contains the revision. The file will still exist in the commits prior to the commit that contains the deletion.
  ## 
  let valid = call_601184.validator(path, query, header, formData, body)
  let scheme = call_601184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601184.url(scheme.get, call_601184.host, call_601184.base,
                         call_601184.route, valid.getOrDefault("path"))
  result = hook(call_601184, url, valid)

proc call*(call_601185: Call_DeleteFile_601172; body: JsonNode): Recallable =
  ## deleteFile
  ## Deletes a specified file from a specified branch. A commit is created on the branch that contains the revision. The file will still exist in the commits prior to the commit that contains the deletion.
  ##   body: JObject (required)
  var body_601186 = newJObject()
  if body != nil:
    body_601186 = body
  result = call_601185.call(nil, nil, nil, nil, body_601186)

var deleteFile* = Call_DeleteFile_601172(name: "deleteFile",
                                      meth: HttpMethod.HttpPost,
                                      host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.DeleteFile",
                                      validator: validate_DeleteFile_601173,
                                      base: "/", url: url_DeleteFile_601174,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRepository_601187 = ref object of OpenApiRestCall_600426
proc url_DeleteRepository_601189(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteRepository_601188(path: JsonNode; query: JsonNode;
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
  var valid_601190 = header.getOrDefault("X-Amz-Date")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Date", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Security-Token")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Security-Token", valid_601191
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601192 = header.getOrDefault("X-Amz-Target")
  valid_601192 = validateParameter(valid_601192, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteRepository"))
  if valid_601192 != nil:
    section.add "X-Amz-Target", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Content-Sha256", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Algorithm")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Algorithm", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Signature")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Signature", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-SignedHeaders", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Credential")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Credential", valid_601197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601199: Call_DeleteRepository_601187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a repository. If a specified repository was already deleted, a null repository ID will be returned.</p> <important> <p>Deleting a repository also deletes all associated objects and metadata. After a repository is deleted, all future push calls to the deleted repository will fail.</p> </important>
  ## 
  let valid = call_601199.validator(path, query, header, formData, body)
  let scheme = call_601199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601199.url(scheme.get, call_601199.host, call_601199.base,
                         call_601199.route, valid.getOrDefault("path"))
  result = hook(call_601199, url, valid)

proc call*(call_601200: Call_DeleteRepository_601187; body: JsonNode): Recallable =
  ## deleteRepository
  ## <p>Deletes a repository. If a specified repository was already deleted, a null repository ID will be returned.</p> <important> <p>Deleting a repository also deletes all associated objects and metadata. After a repository is deleted, all future push calls to the deleted repository will fail.</p> </important>
  ##   body: JObject (required)
  var body_601201 = newJObject()
  if body != nil:
    body_601201 = body
  result = call_601200.call(nil, nil, nil, nil, body_601201)

var deleteRepository* = Call_DeleteRepository_601187(name: "deleteRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteRepository",
    validator: validate_DeleteRepository_601188, base: "/",
    url: url_DeleteRepository_601189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMergeConflicts_601202 = ref object of OpenApiRestCall_600426
proc url_DescribeMergeConflicts_601204(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeMergeConflicts_601203(path: JsonNode; query: JsonNode;
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
  var valid_601205 = query.getOrDefault("maxMergeHunks")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "maxMergeHunks", valid_601205
  var valid_601206 = query.getOrDefault("nextToken")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "nextToken", valid_601206
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
  var valid_601207 = header.getOrDefault("X-Amz-Date")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Date", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Security-Token")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Security-Token", valid_601208
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601209 = header.getOrDefault("X-Amz-Target")
  valid_601209 = validateParameter(valid_601209, JString, required = true, default = newJString(
      "CodeCommit_20150413.DescribeMergeConflicts"))
  if valid_601209 != nil:
    section.add "X-Amz-Target", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Content-Sha256", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-Algorithm")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Algorithm", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Signature")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Signature", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-SignedHeaders", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Credential")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Credential", valid_601214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601216: Call_DescribeMergeConflicts_601202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy. If the merge option for the attempted merge is specified as FAST_FORWARD_MERGE, an exception will be thrown.
  ## 
  let valid = call_601216.validator(path, query, header, formData, body)
  let scheme = call_601216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601216.url(scheme.get, call_601216.host, call_601216.base,
                         call_601216.route, valid.getOrDefault("path"))
  result = hook(call_601216, url, valid)

proc call*(call_601217: Call_DescribeMergeConflicts_601202; body: JsonNode;
          maxMergeHunks: string = ""; nextToken: string = ""): Recallable =
  ## describeMergeConflicts
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy. If the merge option for the attempted merge is specified as FAST_FORWARD_MERGE, an exception will be thrown.
  ##   maxMergeHunks: string
  ##                : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601218 = newJObject()
  var body_601219 = newJObject()
  add(query_601218, "maxMergeHunks", newJString(maxMergeHunks))
  add(query_601218, "nextToken", newJString(nextToken))
  if body != nil:
    body_601219 = body
  result = call_601217.call(nil, query_601218, nil, nil, body_601219)

var describeMergeConflicts* = Call_DescribeMergeConflicts_601202(
    name: "describeMergeConflicts", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DescribeMergeConflicts",
    validator: validate_DescribeMergeConflicts_601203, base: "/",
    url: url_DescribeMergeConflicts_601204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePullRequestEvents_601221 = ref object of OpenApiRestCall_600426
proc url_DescribePullRequestEvents_601223(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribePullRequestEvents_601222(path: JsonNode; query: JsonNode;
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
  var valid_601224 = query.getOrDefault("maxResults")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "maxResults", valid_601224
  var valid_601225 = query.getOrDefault("nextToken")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "nextToken", valid_601225
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
  var valid_601226 = header.getOrDefault("X-Amz-Date")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-Date", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Security-Token")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Security-Token", valid_601227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601228 = header.getOrDefault("X-Amz-Target")
  valid_601228 = validateParameter(valid_601228, JString, required = true, default = newJString(
      "CodeCommit_20150413.DescribePullRequestEvents"))
  if valid_601228 != nil:
    section.add "X-Amz-Target", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Content-Sha256", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Algorithm")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Algorithm", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Signature")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Signature", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-SignedHeaders", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Credential")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Credential", valid_601233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601235: Call_DescribePullRequestEvents_601221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about one or more pull request events.
  ## 
  let valid = call_601235.validator(path, query, header, formData, body)
  let scheme = call_601235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601235.url(scheme.get, call_601235.host, call_601235.base,
                         call_601235.route, valid.getOrDefault("path"))
  result = hook(call_601235, url, valid)

proc call*(call_601236: Call_DescribePullRequestEvents_601221; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describePullRequestEvents
  ## Returns information about one or more pull request events.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601237 = newJObject()
  var body_601238 = newJObject()
  add(query_601237, "maxResults", newJString(maxResults))
  add(query_601237, "nextToken", newJString(nextToken))
  if body != nil:
    body_601238 = body
  result = call_601236.call(nil, query_601237, nil, nil, body_601238)

var describePullRequestEvents* = Call_DescribePullRequestEvents_601221(
    name: "describePullRequestEvents", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DescribePullRequestEvents",
    validator: validate_DescribePullRequestEvents_601222, base: "/",
    url: url_DescribePullRequestEvents_601223,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlob_601239 = ref object of OpenApiRestCall_600426
proc url_GetBlob_601241(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetBlob_601240(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601242 = header.getOrDefault("X-Amz-Date")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Date", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-Security-Token")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Security-Token", valid_601243
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601244 = header.getOrDefault("X-Amz-Target")
  valid_601244 = validateParameter(valid_601244, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetBlob"))
  if valid_601244 != nil:
    section.add "X-Amz-Target", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Content-Sha256", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Algorithm")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Algorithm", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Signature")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Signature", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-SignedHeaders", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Credential")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Credential", valid_601249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601251: Call_GetBlob_601239; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the base-64 encoded content of an individual blob within a repository.
  ## 
  let valid = call_601251.validator(path, query, header, formData, body)
  let scheme = call_601251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601251.url(scheme.get, call_601251.host, call_601251.base,
                         call_601251.route, valid.getOrDefault("path"))
  result = hook(call_601251, url, valid)

proc call*(call_601252: Call_GetBlob_601239; body: JsonNode): Recallable =
  ## getBlob
  ## Returns the base-64 encoded content of an individual blob within a repository.
  ##   body: JObject (required)
  var body_601253 = newJObject()
  if body != nil:
    body_601253 = body
  result = call_601252.call(nil, nil, nil, nil, body_601253)

var getBlob* = Call_GetBlob_601239(name: "getBlob", meth: HttpMethod.HttpPost,
                                host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetBlob",
                                validator: validate_GetBlob_601240, base: "/",
                                url: url_GetBlob_601241,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBranch_601254 = ref object of OpenApiRestCall_600426
proc url_GetBranch_601256(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetBranch_601255(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601257 = header.getOrDefault("X-Amz-Date")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Date", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-Security-Token")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Security-Token", valid_601258
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601259 = header.getOrDefault("X-Amz-Target")
  valid_601259 = validateParameter(valid_601259, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetBranch"))
  if valid_601259 != nil:
    section.add "X-Amz-Target", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Content-Sha256", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-Algorithm")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Algorithm", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Signature")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Signature", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-SignedHeaders", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Credential")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Credential", valid_601264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601266: Call_GetBranch_601254; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a repository branch, including its name and the last commit ID.
  ## 
  let valid = call_601266.validator(path, query, header, formData, body)
  let scheme = call_601266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601266.url(scheme.get, call_601266.host, call_601266.base,
                         call_601266.route, valid.getOrDefault("path"))
  result = hook(call_601266, url, valid)

proc call*(call_601267: Call_GetBranch_601254; body: JsonNode): Recallable =
  ## getBranch
  ## Returns information about a repository branch, including its name and the last commit ID.
  ##   body: JObject (required)
  var body_601268 = newJObject()
  if body != nil:
    body_601268 = body
  result = call_601267.call(nil, nil, nil, nil, body_601268)

var getBranch* = Call_GetBranch_601254(name: "getBranch", meth: HttpMethod.HttpPost,
                                    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetBranch",
                                    validator: validate_GetBranch_601255,
                                    base: "/", url: url_GetBranch_601256,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComment_601269 = ref object of OpenApiRestCall_600426
proc url_GetComment_601271(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetComment_601270(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601272 = header.getOrDefault("X-Amz-Date")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Date", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Security-Token")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Security-Token", valid_601273
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601274 = header.getOrDefault("X-Amz-Target")
  valid_601274 = validateParameter(valid_601274, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetComment"))
  if valid_601274 != nil:
    section.add "X-Amz-Target", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Content-Sha256", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-Algorithm")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Algorithm", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Signature")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Signature", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-SignedHeaders", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Credential")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Credential", valid_601279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601281: Call_GetComment_601269; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the content of a comment made on a change, file, or commit in a repository.
  ## 
  let valid = call_601281.validator(path, query, header, formData, body)
  let scheme = call_601281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601281.url(scheme.get, call_601281.host, call_601281.base,
                         call_601281.route, valid.getOrDefault("path"))
  result = hook(call_601281, url, valid)

proc call*(call_601282: Call_GetComment_601269; body: JsonNode): Recallable =
  ## getComment
  ## Returns the content of a comment made on a change, file, or commit in a repository.
  ##   body: JObject (required)
  var body_601283 = newJObject()
  if body != nil:
    body_601283 = body
  result = call_601282.call(nil, nil, nil, nil, body_601283)

var getComment* = Call_GetComment_601269(name: "getComment",
                                      meth: HttpMethod.HttpPost,
                                      host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetComment",
                                      validator: validate_GetComment_601270,
                                      base: "/", url: url_GetComment_601271,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommentsForComparedCommit_601284 = ref object of OpenApiRestCall_600426
proc url_GetCommentsForComparedCommit_601286(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCommentsForComparedCommit_601285(path: JsonNode; query: JsonNode;
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
  var valid_601287 = query.getOrDefault("maxResults")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "maxResults", valid_601287
  var valid_601288 = query.getOrDefault("nextToken")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "nextToken", valid_601288
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
  var valid_601289 = header.getOrDefault("X-Amz-Date")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Date", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Security-Token")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Security-Token", valid_601290
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601291 = header.getOrDefault("X-Amz-Target")
  valid_601291 = validateParameter(valid_601291, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommentsForComparedCommit"))
  if valid_601291 != nil:
    section.add "X-Amz-Target", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Content-Sha256", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Algorithm")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Algorithm", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Signature")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Signature", valid_601294
  var valid_601295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-SignedHeaders", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Credential")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Credential", valid_601296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601298: Call_GetCommentsForComparedCommit_601284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about comments made on the comparison between two commits.
  ## 
  let valid = call_601298.validator(path, query, header, formData, body)
  let scheme = call_601298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601298.url(scheme.get, call_601298.host, call_601298.base,
                         call_601298.route, valid.getOrDefault("path"))
  result = hook(call_601298, url, valid)

proc call*(call_601299: Call_GetCommentsForComparedCommit_601284; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getCommentsForComparedCommit
  ## Returns information about comments made on the comparison between two commits.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601300 = newJObject()
  var body_601301 = newJObject()
  add(query_601300, "maxResults", newJString(maxResults))
  add(query_601300, "nextToken", newJString(nextToken))
  if body != nil:
    body_601301 = body
  result = call_601299.call(nil, query_601300, nil, nil, body_601301)

var getCommentsForComparedCommit* = Call_GetCommentsForComparedCommit_601284(
    name: "getCommentsForComparedCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetCommentsForComparedCommit",
    validator: validate_GetCommentsForComparedCommit_601285, base: "/",
    url: url_GetCommentsForComparedCommit_601286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommentsForPullRequest_601302 = ref object of OpenApiRestCall_600426
proc url_GetCommentsForPullRequest_601304(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCommentsForPullRequest_601303(path: JsonNode; query: JsonNode;
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
  var valid_601305 = query.getOrDefault("maxResults")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "maxResults", valid_601305
  var valid_601306 = query.getOrDefault("nextToken")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "nextToken", valid_601306
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
  var valid_601307 = header.getOrDefault("X-Amz-Date")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Date", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Security-Token")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Security-Token", valid_601308
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601309 = header.getOrDefault("X-Amz-Target")
  valid_601309 = validateParameter(valid_601309, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommentsForPullRequest"))
  if valid_601309 != nil:
    section.add "X-Amz-Target", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Content-Sha256", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-Algorithm")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-Algorithm", valid_601311
  var valid_601312 = header.getOrDefault("X-Amz-Signature")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Signature", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-SignedHeaders", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-Credential")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Credential", valid_601314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601316: Call_GetCommentsForPullRequest_601302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns comments made on a pull request.
  ## 
  let valid = call_601316.validator(path, query, header, formData, body)
  let scheme = call_601316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601316.url(scheme.get, call_601316.host, call_601316.base,
                         call_601316.route, valid.getOrDefault("path"))
  result = hook(call_601316, url, valid)

proc call*(call_601317: Call_GetCommentsForPullRequest_601302; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getCommentsForPullRequest
  ## Returns comments made on a pull request.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601318 = newJObject()
  var body_601319 = newJObject()
  add(query_601318, "maxResults", newJString(maxResults))
  add(query_601318, "nextToken", newJString(nextToken))
  if body != nil:
    body_601319 = body
  result = call_601317.call(nil, query_601318, nil, nil, body_601319)

var getCommentsForPullRequest* = Call_GetCommentsForPullRequest_601302(
    name: "getCommentsForPullRequest", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetCommentsForPullRequest",
    validator: validate_GetCommentsForPullRequest_601303, base: "/",
    url: url_GetCommentsForPullRequest_601304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommit_601320 = ref object of OpenApiRestCall_600426
proc url_GetCommit_601322(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCommit_601321(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601323 = header.getOrDefault("X-Amz-Date")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-Date", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-Security-Token")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Security-Token", valid_601324
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601325 = header.getOrDefault("X-Amz-Target")
  valid_601325 = validateParameter(valid_601325, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommit"))
  if valid_601325 != nil:
    section.add "X-Amz-Target", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Content-Sha256", valid_601326
  var valid_601327 = header.getOrDefault("X-Amz-Algorithm")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-Algorithm", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-Signature")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Signature", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-SignedHeaders", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-Credential")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Credential", valid_601330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601332: Call_GetCommit_601320; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a commit, including commit message and committer information.
  ## 
  let valid = call_601332.validator(path, query, header, formData, body)
  let scheme = call_601332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601332.url(scheme.get, call_601332.host, call_601332.base,
                         call_601332.route, valid.getOrDefault("path"))
  result = hook(call_601332, url, valid)

proc call*(call_601333: Call_GetCommit_601320; body: JsonNode): Recallable =
  ## getCommit
  ## Returns information about a commit, including commit message and committer information.
  ##   body: JObject (required)
  var body_601334 = newJObject()
  if body != nil:
    body_601334 = body
  result = call_601333.call(nil, nil, nil, nil, body_601334)

var getCommit* = Call_GetCommit_601320(name: "getCommit", meth: HttpMethod.HttpPost,
                                    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetCommit",
                                    validator: validate_GetCommit_601321,
                                    base: "/", url: url_GetCommit_601322,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDifferences_601335 = ref object of OpenApiRestCall_600426
proc url_GetDifferences_601337(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDifferences_601336(path: JsonNode; query: JsonNode;
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
  var valid_601338 = query.getOrDefault("NextToken")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "NextToken", valid_601338
  var valid_601339 = query.getOrDefault("MaxResults")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "MaxResults", valid_601339
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
  var valid_601340 = header.getOrDefault("X-Amz-Date")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Date", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-Security-Token")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Security-Token", valid_601341
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601342 = header.getOrDefault("X-Amz-Target")
  valid_601342 = validateParameter(valid_601342, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetDifferences"))
  if valid_601342 != nil:
    section.add "X-Amz-Target", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Content-Sha256", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Algorithm")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Algorithm", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Signature")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Signature", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-SignedHeaders", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-Credential")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Credential", valid_601347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601349: Call_GetDifferences_601335; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID or other fully qualified reference). Results can be limited to a specified path.
  ## 
  let valid = call_601349.validator(path, query, header, formData, body)
  let scheme = call_601349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601349.url(scheme.get, call_601349.host, call_601349.base,
                         call_601349.route, valid.getOrDefault("path"))
  result = hook(call_601349, url, valid)

proc call*(call_601350: Call_GetDifferences_601335; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getDifferences
  ## Returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID or other fully qualified reference). Results can be limited to a specified path.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601351 = newJObject()
  var body_601352 = newJObject()
  add(query_601351, "NextToken", newJString(NextToken))
  if body != nil:
    body_601352 = body
  add(query_601351, "MaxResults", newJString(MaxResults))
  result = call_601350.call(nil, query_601351, nil, nil, body_601352)

var getDifferences* = Call_GetDifferences_601335(name: "getDifferences",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetDifferences",
    validator: validate_GetDifferences_601336, base: "/", url: url_GetDifferences_601337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFile_601353 = ref object of OpenApiRestCall_600426
proc url_GetFile_601355(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetFile_601354(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601356 = header.getOrDefault("X-Amz-Date")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Date", valid_601356
  var valid_601357 = header.getOrDefault("X-Amz-Security-Token")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Security-Token", valid_601357
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601358 = header.getOrDefault("X-Amz-Target")
  valid_601358 = validateParameter(valid_601358, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetFile"))
  if valid_601358 != nil:
    section.add "X-Amz-Target", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Content-Sha256", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Algorithm")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Algorithm", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Signature")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Signature", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-SignedHeaders", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-Credential")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Credential", valid_601363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601365: Call_GetFile_601353; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the base-64 encoded contents of a specified file and its metadata.
  ## 
  let valid = call_601365.validator(path, query, header, formData, body)
  let scheme = call_601365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601365.url(scheme.get, call_601365.host, call_601365.base,
                         call_601365.route, valid.getOrDefault("path"))
  result = hook(call_601365, url, valid)

proc call*(call_601366: Call_GetFile_601353; body: JsonNode): Recallable =
  ## getFile
  ## Returns the base-64 encoded contents of a specified file and its metadata.
  ##   body: JObject (required)
  var body_601367 = newJObject()
  if body != nil:
    body_601367 = body
  result = call_601366.call(nil, nil, nil, nil, body_601367)

var getFile* = Call_GetFile_601353(name: "getFile", meth: HttpMethod.HttpPost,
                                host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetFile",
                                validator: validate_GetFile_601354, base: "/",
                                url: url_GetFile_601355,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolder_601368 = ref object of OpenApiRestCall_600426
proc url_GetFolder_601370(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetFolder_601369(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601371 = header.getOrDefault("X-Amz-Date")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-Date", valid_601371
  var valid_601372 = header.getOrDefault("X-Amz-Security-Token")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Security-Token", valid_601372
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601373 = header.getOrDefault("X-Amz-Target")
  valid_601373 = validateParameter(valid_601373, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetFolder"))
  if valid_601373 != nil:
    section.add "X-Amz-Target", valid_601373
  var valid_601374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "X-Amz-Content-Sha256", valid_601374
  var valid_601375 = header.getOrDefault("X-Amz-Algorithm")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "X-Amz-Algorithm", valid_601375
  var valid_601376 = header.getOrDefault("X-Amz-Signature")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-Signature", valid_601376
  var valid_601377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-SignedHeaders", valid_601377
  var valid_601378 = header.getOrDefault("X-Amz-Credential")
  valid_601378 = validateParameter(valid_601378, JString, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "X-Amz-Credential", valid_601378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601380: Call_GetFolder_601368; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the contents of a specified folder in a repository.
  ## 
  let valid = call_601380.validator(path, query, header, formData, body)
  let scheme = call_601380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601380.url(scheme.get, call_601380.host, call_601380.base,
                         call_601380.route, valid.getOrDefault("path"))
  result = hook(call_601380, url, valid)

proc call*(call_601381: Call_GetFolder_601368; body: JsonNode): Recallable =
  ## getFolder
  ## Returns the contents of a specified folder in a repository.
  ##   body: JObject (required)
  var body_601382 = newJObject()
  if body != nil:
    body_601382 = body
  result = call_601381.call(nil, nil, nil, nil, body_601382)

var getFolder* = Call_GetFolder_601368(name: "getFolder", meth: HttpMethod.HttpPost,
                                    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetFolder",
                                    validator: validate_GetFolder_601369,
                                    base: "/", url: url_GetFolder_601370,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeCommit_601383 = ref object of OpenApiRestCall_600426
proc url_GetMergeCommit_601385(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMergeCommit_601384(path: JsonNode; query: JsonNode;
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
  var valid_601386 = header.getOrDefault("X-Amz-Date")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-Date", valid_601386
  var valid_601387 = header.getOrDefault("X-Amz-Security-Token")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-Security-Token", valid_601387
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601388 = header.getOrDefault("X-Amz-Target")
  valid_601388 = validateParameter(valid_601388, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeCommit"))
  if valid_601388 != nil:
    section.add "X-Amz-Target", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-Content-Sha256", valid_601389
  var valid_601390 = header.getOrDefault("X-Amz-Algorithm")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-Algorithm", valid_601390
  var valid_601391 = header.getOrDefault("X-Amz-Signature")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-Signature", valid_601391
  var valid_601392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-SignedHeaders", valid_601392
  var valid_601393 = header.getOrDefault("X-Amz-Credential")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "X-Amz-Credential", valid_601393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601395: Call_GetMergeCommit_601383; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified merge commit.
  ## 
  let valid = call_601395.validator(path, query, header, formData, body)
  let scheme = call_601395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601395.url(scheme.get, call_601395.host, call_601395.base,
                         call_601395.route, valid.getOrDefault("path"))
  result = hook(call_601395, url, valid)

proc call*(call_601396: Call_GetMergeCommit_601383; body: JsonNode): Recallable =
  ## getMergeCommit
  ## Returns information about a specified merge commit.
  ##   body: JObject (required)
  var body_601397 = newJObject()
  if body != nil:
    body_601397 = body
  result = call_601396.call(nil, nil, nil, nil, body_601397)

var getMergeCommit* = Call_GetMergeCommit_601383(name: "getMergeCommit",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeCommit",
    validator: validate_GetMergeCommit_601384, base: "/", url: url_GetMergeCommit_601385,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeConflicts_601398 = ref object of OpenApiRestCall_600426
proc url_GetMergeConflicts_601400(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMergeConflicts_601399(path: JsonNode; query: JsonNode;
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
  var valid_601401 = query.getOrDefault("nextToken")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "nextToken", valid_601401
  var valid_601402 = query.getOrDefault("maxConflictFiles")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "maxConflictFiles", valid_601402
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
  var valid_601403 = header.getOrDefault("X-Amz-Date")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Date", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Security-Token")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Security-Token", valid_601404
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601405 = header.getOrDefault("X-Amz-Target")
  valid_601405 = validateParameter(valid_601405, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeConflicts"))
  if valid_601405 != nil:
    section.add "X-Amz-Target", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-Content-Sha256", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-Algorithm")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Algorithm", valid_601407
  var valid_601408 = header.getOrDefault("X-Amz-Signature")
  valid_601408 = validateParameter(valid_601408, JString, required = false,
                                 default = nil)
  if valid_601408 != nil:
    section.add "X-Amz-Signature", valid_601408
  var valid_601409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601409 = validateParameter(valid_601409, JString, required = false,
                                 default = nil)
  if valid_601409 != nil:
    section.add "X-Amz-SignedHeaders", valid_601409
  var valid_601410 = header.getOrDefault("X-Amz-Credential")
  valid_601410 = validateParameter(valid_601410, JString, required = false,
                                 default = nil)
  if valid_601410 != nil:
    section.add "X-Amz-Credential", valid_601410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601412: Call_GetMergeConflicts_601398; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about merge conflicts between the before and after commit IDs for a pull request in a repository.
  ## 
  let valid = call_601412.validator(path, query, header, formData, body)
  let scheme = call_601412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601412.url(scheme.get, call_601412.host, call_601412.base,
                         call_601412.route, valid.getOrDefault("path"))
  result = hook(call_601412, url, valid)

proc call*(call_601413: Call_GetMergeConflicts_601398; body: JsonNode;
          nextToken: string = ""; maxConflictFiles: string = ""): Recallable =
  ## getMergeConflicts
  ## Returns information about merge conflicts between the before and after commit IDs for a pull request in a repository.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxConflictFiles: string
  ##                   : Pagination limit
  var query_601414 = newJObject()
  var body_601415 = newJObject()
  add(query_601414, "nextToken", newJString(nextToken))
  if body != nil:
    body_601415 = body
  add(query_601414, "maxConflictFiles", newJString(maxConflictFiles))
  result = call_601413.call(nil, query_601414, nil, nil, body_601415)

var getMergeConflicts* = Call_GetMergeConflicts_601398(name: "getMergeConflicts",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeConflicts",
    validator: validate_GetMergeConflicts_601399, base: "/",
    url: url_GetMergeConflicts_601400, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeOptions_601416 = ref object of OpenApiRestCall_600426
proc url_GetMergeOptions_601418(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetMergeOptions_601417(path: JsonNode; query: JsonNode;
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
  var valid_601419 = header.getOrDefault("X-Amz-Date")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Date", valid_601419
  var valid_601420 = header.getOrDefault("X-Amz-Security-Token")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-Security-Token", valid_601420
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601421 = header.getOrDefault("X-Amz-Target")
  valid_601421 = validateParameter(valid_601421, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeOptions"))
  if valid_601421 != nil:
    section.add "X-Amz-Target", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Content-Sha256", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Algorithm")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Algorithm", valid_601423
  var valid_601424 = header.getOrDefault("X-Amz-Signature")
  valid_601424 = validateParameter(valid_601424, JString, required = false,
                                 default = nil)
  if valid_601424 != nil:
    section.add "X-Amz-Signature", valid_601424
  var valid_601425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-SignedHeaders", valid_601425
  var valid_601426 = header.getOrDefault("X-Amz-Credential")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "X-Amz-Credential", valid_601426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601428: Call_GetMergeOptions_601416; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the merge options available for merging two specified branches. For details about why a particular merge option is not available, use GetMergeConflicts or DescribeMergeConflicts.
  ## 
  let valid = call_601428.validator(path, query, header, formData, body)
  let scheme = call_601428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601428.url(scheme.get, call_601428.host, call_601428.base,
                         call_601428.route, valid.getOrDefault("path"))
  result = hook(call_601428, url, valid)

proc call*(call_601429: Call_GetMergeOptions_601416; body: JsonNode): Recallable =
  ## getMergeOptions
  ## Returns information about the merge options available for merging two specified branches. For details about why a particular merge option is not available, use GetMergeConflicts or DescribeMergeConflicts.
  ##   body: JObject (required)
  var body_601430 = newJObject()
  if body != nil:
    body_601430 = body
  result = call_601429.call(nil, nil, nil, nil, body_601430)

var getMergeOptions* = Call_GetMergeOptions_601416(name: "getMergeOptions",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeOptions",
    validator: validate_GetMergeOptions_601417, base: "/", url: url_GetMergeOptions_601418,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPullRequest_601431 = ref object of OpenApiRestCall_600426
proc url_GetPullRequest_601433(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPullRequest_601432(path: JsonNode; query: JsonNode;
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
  var valid_601434 = header.getOrDefault("X-Amz-Date")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Date", valid_601434
  var valid_601435 = header.getOrDefault("X-Amz-Security-Token")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-Security-Token", valid_601435
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601436 = header.getOrDefault("X-Amz-Target")
  valid_601436 = validateParameter(valid_601436, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetPullRequest"))
  if valid_601436 != nil:
    section.add "X-Amz-Target", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Content-Sha256", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-Algorithm")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Algorithm", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-Signature")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Signature", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-SignedHeaders", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Credential")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Credential", valid_601441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601443: Call_GetPullRequest_601431; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a pull request in a specified repository.
  ## 
  let valid = call_601443.validator(path, query, header, formData, body)
  let scheme = call_601443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601443.url(scheme.get, call_601443.host, call_601443.base,
                         call_601443.route, valid.getOrDefault("path"))
  result = hook(call_601443, url, valid)

proc call*(call_601444: Call_GetPullRequest_601431; body: JsonNode): Recallable =
  ## getPullRequest
  ## Gets information about a pull request in a specified repository.
  ##   body: JObject (required)
  var body_601445 = newJObject()
  if body != nil:
    body_601445 = body
  result = call_601444.call(nil, nil, nil, nil, body_601445)

var getPullRequest* = Call_GetPullRequest_601431(name: "getPullRequest",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetPullRequest",
    validator: validate_GetPullRequest_601432, base: "/", url: url_GetPullRequest_601433,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepository_601446 = ref object of OpenApiRestCall_600426
proc url_GetRepository_601448(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRepository_601447(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601449 = header.getOrDefault("X-Amz-Date")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "X-Amz-Date", valid_601449
  var valid_601450 = header.getOrDefault("X-Amz-Security-Token")
  valid_601450 = validateParameter(valid_601450, JString, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "X-Amz-Security-Token", valid_601450
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601451 = header.getOrDefault("X-Amz-Target")
  valid_601451 = validateParameter(valid_601451, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetRepository"))
  if valid_601451 != nil:
    section.add "X-Amz-Target", valid_601451
  var valid_601452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Content-Sha256", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-Algorithm")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-Algorithm", valid_601453
  var valid_601454 = header.getOrDefault("X-Amz-Signature")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-Signature", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-SignedHeaders", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-Credential")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-Credential", valid_601456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601458: Call_GetRepository_601446; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ## 
  let valid = call_601458.validator(path, query, header, formData, body)
  let scheme = call_601458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601458.url(scheme.get, call_601458.host, call_601458.base,
                         call_601458.route, valid.getOrDefault("path"))
  result = hook(call_601458, url, valid)

proc call*(call_601459: Call_GetRepository_601446; body: JsonNode): Recallable =
  ## getRepository
  ## <p>Returns information about a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ##   body: JObject (required)
  var body_601460 = newJObject()
  if body != nil:
    body_601460 = body
  result = call_601459.call(nil, nil, nil, nil, body_601460)

var getRepository* = Call_GetRepository_601446(name: "getRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetRepository",
    validator: validate_GetRepository_601447, base: "/", url: url_GetRepository_601448,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepositoryTriggers_601461 = ref object of OpenApiRestCall_600426
proc url_GetRepositoryTriggers_601463(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRepositoryTriggers_601462(path: JsonNode; query: JsonNode;
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
  var valid_601464 = header.getOrDefault("X-Amz-Date")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "X-Amz-Date", valid_601464
  var valid_601465 = header.getOrDefault("X-Amz-Security-Token")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-Security-Token", valid_601465
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601466 = header.getOrDefault("X-Amz-Target")
  valid_601466 = validateParameter(valid_601466, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetRepositoryTriggers"))
  if valid_601466 != nil:
    section.add "X-Amz-Target", valid_601466
  var valid_601467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Content-Sha256", valid_601467
  var valid_601468 = header.getOrDefault("X-Amz-Algorithm")
  valid_601468 = validateParameter(valid_601468, JString, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "X-Amz-Algorithm", valid_601468
  var valid_601469 = header.getOrDefault("X-Amz-Signature")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "X-Amz-Signature", valid_601469
  var valid_601470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-SignedHeaders", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Credential")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Credential", valid_601471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601473: Call_GetRepositoryTriggers_601461; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about triggers configured for a repository.
  ## 
  let valid = call_601473.validator(path, query, header, formData, body)
  let scheme = call_601473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601473.url(scheme.get, call_601473.host, call_601473.base,
                         call_601473.route, valid.getOrDefault("path"))
  result = hook(call_601473, url, valid)

proc call*(call_601474: Call_GetRepositoryTriggers_601461; body: JsonNode): Recallable =
  ## getRepositoryTriggers
  ## Gets information about triggers configured for a repository.
  ##   body: JObject (required)
  var body_601475 = newJObject()
  if body != nil:
    body_601475 = body
  result = call_601474.call(nil, nil, nil, nil, body_601475)

var getRepositoryTriggers* = Call_GetRepositoryTriggers_601461(
    name: "getRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetRepositoryTriggers",
    validator: validate_GetRepositoryTriggers_601462, base: "/",
    url: url_GetRepositoryTriggers_601463, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBranches_601476 = ref object of OpenApiRestCall_600426
proc url_ListBranches_601478(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListBranches_601477(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601479 = query.getOrDefault("nextToken")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "nextToken", valid_601479
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
  var valid_601480 = header.getOrDefault("X-Amz-Date")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-Date", valid_601480
  var valid_601481 = header.getOrDefault("X-Amz-Security-Token")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-Security-Token", valid_601481
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601482 = header.getOrDefault("X-Amz-Target")
  valid_601482 = validateParameter(valid_601482, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListBranches"))
  if valid_601482 != nil:
    section.add "X-Amz-Target", valid_601482
  var valid_601483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Content-Sha256", valid_601483
  var valid_601484 = header.getOrDefault("X-Amz-Algorithm")
  valid_601484 = validateParameter(valid_601484, JString, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "X-Amz-Algorithm", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-Signature")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Signature", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-SignedHeaders", valid_601486
  var valid_601487 = header.getOrDefault("X-Amz-Credential")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "X-Amz-Credential", valid_601487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601489: Call_ListBranches_601476; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more branches in a repository.
  ## 
  let valid = call_601489.validator(path, query, header, formData, body)
  let scheme = call_601489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601489.url(scheme.get, call_601489.host, call_601489.base,
                         call_601489.route, valid.getOrDefault("path"))
  result = hook(call_601489, url, valid)

proc call*(call_601490: Call_ListBranches_601476; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listBranches
  ## Gets information about one or more branches in a repository.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601491 = newJObject()
  var body_601492 = newJObject()
  add(query_601491, "nextToken", newJString(nextToken))
  if body != nil:
    body_601492 = body
  result = call_601490.call(nil, query_601491, nil, nil, body_601492)

var listBranches* = Call_ListBranches_601476(name: "listBranches",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListBranches",
    validator: validate_ListBranches_601477, base: "/", url: url_ListBranches_601478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPullRequests_601493 = ref object of OpenApiRestCall_600426
proc url_ListPullRequests_601495(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPullRequests_601494(path: JsonNode; query: JsonNode;
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
  var valid_601496 = query.getOrDefault("maxResults")
  valid_601496 = validateParameter(valid_601496, JString, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "maxResults", valid_601496
  var valid_601497 = query.getOrDefault("nextToken")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "nextToken", valid_601497
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
  var valid_601498 = header.getOrDefault("X-Amz-Date")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-Date", valid_601498
  var valid_601499 = header.getOrDefault("X-Amz-Security-Token")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "X-Amz-Security-Token", valid_601499
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601500 = header.getOrDefault("X-Amz-Target")
  valid_601500 = validateParameter(valid_601500, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListPullRequests"))
  if valid_601500 != nil:
    section.add "X-Amz-Target", valid_601500
  var valid_601501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-Content-Sha256", valid_601501
  var valid_601502 = header.getOrDefault("X-Amz-Algorithm")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-Algorithm", valid_601502
  var valid_601503 = header.getOrDefault("X-Amz-Signature")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-Signature", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-SignedHeaders", valid_601504
  var valid_601505 = header.getOrDefault("X-Amz-Credential")
  valid_601505 = validateParameter(valid_601505, JString, required = false,
                                 default = nil)
  if valid_601505 != nil:
    section.add "X-Amz-Credential", valid_601505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601507: Call_ListPullRequests_601493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of pull requests for a specified repository. The return list can be refined by pull request status or pull request author ARN.
  ## 
  let valid = call_601507.validator(path, query, header, formData, body)
  let scheme = call_601507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601507.url(scheme.get, call_601507.host, call_601507.base,
                         call_601507.route, valid.getOrDefault("path"))
  result = hook(call_601507, url, valid)

proc call*(call_601508: Call_ListPullRequests_601493; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listPullRequests
  ## Returns a list of pull requests for a specified repository. The return list can be refined by pull request status or pull request author ARN.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601509 = newJObject()
  var body_601510 = newJObject()
  add(query_601509, "maxResults", newJString(maxResults))
  add(query_601509, "nextToken", newJString(nextToken))
  if body != nil:
    body_601510 = body
  result = call_601508.call(nil, query_601509, nil, nil, body_601510)

var listPullRequests* = Call_ListPullRequests_601493(name: "listPullRequests",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListPullRequests",
    validator: validate_ListPullRequests_601494, base: "/",
    url: url_ListPullRequests_601495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRepositories_601511 = ref object of OpenApiRestCall_600426
proc url_ListRepositories_601513(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListRepositories_601512(path: JsonNode; query: JsonNode;
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
  var valid_601514 = query.getOrDefault("nextToken")
  valid_601514 = validateParameter(valid_601514, JString, required = false,
                                 default = nil)
  if valid_601514 != nil:
    section.add "nextToken", valid_601514
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
  var valid_601515 = header.getOrDefault("X-Amz-Date")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Date", valid_601515
  var valid_601516 = header.getOrDefault("X-Amz-Security-Token")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-Security-Token", valid_601516
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601517 = header.getOrDefault("X-Amz-Target")
  valid_601517 = validateParameter(valid_601517, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListRepositories"))
  if valid_601517 != nil:
    section.add "X-Amz-Target", valid_601517
  var valid_601518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Content-Sha256", valid_601518
  var valid_601519 = header.getOrDefault("X-Amz-Algorithm")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Algorithm", valid_601519
  var valid_601520 = header.getOrDefault("X-Amz-Signature")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "X-Amz-Signature", valid_601520
  var valid_601521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-SignedHeaders", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-Credential")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-Credential", valid_601522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601524: Call_ListRepositories_601511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more repositories.
  ## 
  let valid = call_601524.validator(path, query, header, formData, body)
  let scheme = call_601524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601524.url(scheme.get, call_601524.host, call_601524.base,
                         call_601524.route, valid.getOrDefault("path"))
  result = hook(call_601524, url, valid)

proc call*(call_601525: Call_ListRepositories_601511; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listRepositories
  ## Gets information about one or more repositories.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601526 = newJObject()
  var body_601527 = newJObject()
  add(query_601526, "nextToken", newJString(nextToken))
  if body != nil:
    body_601527 = body
  result = call_601525.call(nil, query_601526, nil, nil, body_601527)

var listRepositories* = Call_ListRepositories_601511(name: "listRepositories",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListRepositories",
    validator: validate_ListRepositories_601512, base: "/",
    url: url_ListRepositories_601513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601528 = ref object of OpenApiRestCall_600426
proc url_ListTagsForResource_601530(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_601529(path: JsonNode; query: JsonNode;
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
  var valid_601531 = header.getOrDefault("X-Amz-Date")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-Date", valid_601531
  var valid_601532 = header.getOrDefault("X-Amz-Security-Token")
  valid_601532 = validateParameter(valid_601532, JString, required = false,
                                 default = nil)
  if valid_601532 != nil:
    section.add "X-Amz-Security-Token", valid_601532
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601533 = header.getOrDefault("X-Amz-Target")
  valid_601533 = validateParameter(valid_601533, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListTagsForResource"))
  if valid_601533 != nil:
    section.add "X-Amz-Target", valid_601533
  var valid_601534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-Content-Sha256", valid_601534
  var valid_601535 = header.getOrDefault("X-Amz-Algorithm")
  valid_601535 = validateParameter(valid_601535, JString, required = false,
                                 default = nil)
  if valid_601535 != nil:
    section.add "X-Amz-Algorithm", valid_601535
  var valid_601536 = header.getOrDefault("X-Amz-Signature")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-Signature", valid_601536
  var valid_601537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-SignedHeaders", valid_601537
  var valid_601538 = header.getOrDefault("X-Amz-Credential")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-Credential", valid_601538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601540: Call_ListTagsForResource_601528; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ## 
  let valid = call_601540.validator(path, query, header, formData, body)
  let scheme = call_601540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601540.url(scheme.get, call_601540.host, call_601540.base,
                         call_601540.route, valid.getOrDefault("path"))
  result = hook(call_601540, url, valid)

proc call*(call_601541: Call_ListTagsForResource_601528; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ##   body: JObject (required)
  var body_601542 = newJObject()
  if body != nil:
    body_601542 = body
  result = call_601541.call(nil, nil, nil, nil, body_601542)

var listTagsForResource* = Call_ListTagsForResource_601528(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListTagsForResource",
    validator: validate_ListTagsForResource_601529, base: "/",
    url: url_ListTagsForResource_601530, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesByFastForward_601543 = ref object of OpenApiRestCall_600426
proc url_MergeBranchesByFastForward_601545(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_MergeBranchesByFastForward_601544(path: JsonNode; query: JsonNode;
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
  var valid_601546 = header.getOrDefault("X-Amz-Date")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "X-Amz-Date", valid_601546
  var valid_601547 = header.getOrDefault("X-Amz-Security-Token")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "X-Amz-Security-Token", valid_601547
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601548 = header.getOrDefault("X-Amz-Target")
  valid_601548 = validateParameter(valid_601548, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesByFastForward"))
  if valid_601548 != nil:
    section.add "X-Amz-Target", valid_601548
  var valid_601549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-Content-Sha256", valid_601549
  var valid_601550 = header.getOrDefault("X-Amz-Algorithm")
  valid_601550 = validateParameter(valid_601550, JString, required = false,
                                 default = nil)
  if valid_601550 != nil:
    section.add "X-Amz-Algorithm", valid_601550
  var valid_601551 = header.getOrDefault("X-Amz-Signature")
  valid_601551 = validateParameter(valid_601551, JString, required = false,
                                 default = nil)
  if valid_601551 != nil:
    section.add "X-Amz-Signature", valid_601551
  var valid_601552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-SignedHeaders", valid_601552
  var valid_601553 = header.getOrDefault("X-Amz-Credential")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "X-Amz-Credential", valid_601553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601555: Call_MergeBranchesByFastForward_601543; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Merges two branches using the fast-forward merge strategy.
  ## 
  let valid = call_601555.validator(path, query, header, formData, body)
  let scheme = call_601555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601555.url(scheme.get, call_601555.host, call_601555.base,
                         call_601555.route, valid.getOrDefault("path"))
  result = hook(call_601555, url, valid)

proc call*(call_601556: Call_MergeBranchesByFastForward_601543; body: JsonNode): Recallable =
  ## mergeBranchesByFastForward
  ## Merges two branches using the fast-forward merge strategy.
  ##   body: JObject (required)
  var body_601557 = newJObject()
  if body != nil:
    body_601557 = body
  result = call_601556.call(nil, nil, nil, nil, body_601557)

var mergeBranchesByFastForward* = Call_MergeBranchesByFastForward_601543(
    name: "mergeBranchesByFastForward", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesByFastForward",
    validator: validate_MergeBranchesByFastForward_601544, base: "/",
    url: url_MergeBranchesByFastForward_601545,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesBySquash_601558 = ref object of OpenApiRestCall_600426
proc url_MergeBranchesBySquash_601560(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_MergeBranchesBySquash_601559(path: JsonNode; query: JsonNode;
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
  var valid_601561 = header.getOrDefault("X-Amz-Date")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-Date", valid_601561
  var valid_601562 = header.getOrDefault("X-Amz-Security-Token")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "X-Amz-Security-Token", valid_601562
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601563 = header.getOrDefault("X-Amz-Target")
  valid_601563 = validateParameter(valid_601563, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesBySquash"))
  if valid_601563 != nil:
    section.add "X-Amz-Target", valid_601563
  var valid_601564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "X-Amz-Content-Sha256", valid_601564
  var valid_601565 = header.getOrDefault("X-Amz-Algorithm")
  valid_601565 = validateParameter(valid_601565, JString, required = false,
                                 default = nil)
  if valid_601565 != nil:
    section.add "X-Amz-Algorithm", valid_601565
  var valid_601566 = header.getOrDefault("X-Amz-Signature")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "X-Amz-Signature", valid_601566
  var valid_601567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "X-Amz-SignedHeaders", valid_601567
  var valid_601568 = header.getOrDefault("X-Amz-Credential")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "X-Amz-Credential", valid_601568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601570: Call_MergeBranchesBySquash_601558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Merges two branches using the squash merge strategy.
  ## 
  let valid = call_601570.validator(path, query, header, formData, body)
  let scheme = call_601570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601570.url(scheme.get, call_601570.host, call_601570.base,
                         call_601570.route, valid.getOrDefault("path"))
  result = hook(call_601570, url, valid)

proc call*(call_601571: Call_MergeBranchesBySquash_601558; body: JsonNode): Recallable =
  ## mergeBranchesBySquash
  ## Merges two branches using the squash merge strategy.
  ##   body: JObject (required)
  var body_601572 = newJObject()
  if body != nil:
    body_601572 = body
  result = call_601571.call(nil, nil, nil, nil, body_601572)

var mergeBranchesBySquash* = Call_MergeBranchesBySquash_601558(
    name: "mergeBranchesBySquash", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesBySquash",
    validator: validate_MergeBranchesBySquash_601559, base: "/",
    url: url_MergeBranchesBySquash_601560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesByThreeWay_601573 = ref object of OpenApiRestCall_600426
proc url_MergeBranchesByThreeWay_601575(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_MergeBranchesByThreeWay_601574(path: JsonNode; query: JsonNode;
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
  var valid_601576 = header.getOrDefault("X-Amz-Date")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "X-Amz-Date", valid_601576
  var valid_601577 = header.getOrDefault("X-Amz-Security-Token")
  valid_601577 = validateParameter(valid_601577, JString, required = false,
                                 default = nil)
  if valid_601577 != nil:
    section.add "X-Amz-Security-Token", valid_601577
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601578 = header.getOrDefault("X-Amz-Target")
  valid_601578 = validateParameter(valid_601578, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesByThreeWay"))
  if valid_601578 != nil:
    section.add "X-Amz-Target", valid_601578
  var valid_601579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601579 = validateParameter(valid_601579, JString, required = false,
                                 default = nil)
  if valid_601579 != nil:
    section.add "X-Amz-Content-Sha256", valid_601579
  var valid_601580 = header.getOrDefault("X-Amz-Algorithm")
  valid_601580 = validateParameter(valid_601580, JString, required = false,
                                 default = nil)
  if valid_601580 != nil:
    section.add "X-Amz-Algorithm", valid_601580
  var valid_601581 = header.getOrDefault("X-Amz-Signature")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "X-Amz-Signature", valid_601581
  var valid_601582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-SignedHeaders", valid_601582
  var valid_601583 = header.getOrDefault("X-Amz-Credential")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "X-Amz-Credential", valid_601583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601585: Call_MergeBranchesByThreeWay_601573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Merges two specified branches using the three-way merge strategy.
  ## 
  let valid = call_601585.validator(path, query, header, formData, body)
  let scheme = call_601585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601585.url(scheme.get, call_601585.host, call_601585.base,
                         call_601585.route, valid.getOrDefault("path"))
  result = hook(call_601585, url, valid)

proc call*(call_601586: Call_MergeBranchesByThreeWay_601573; body: JsonNode): Recallable =
  ## mergeBranchesByThreeWay
  ## Merges two specified branches using the three-way merge strategy.
  ##   body: JObject (required)
  var body_601587 = newJObject()
  if body != nil:
    body_601587 = body
  result = call_601586.call(nil, nil, nil, nil, body_601587)

var mergeBranchesByThreeWay* = Call_MergeBranchesByThreeWay_601573(
    name: "mergeBranchesByThreeWay", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesByThreeWay",
    validator: validate_MergeBranchesByThreeWay_601574, base: "/",
    url: url_MergeBranchesByThreeWay_601575, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestByFastForward_601588 = ref object of OpenApiRestCall_600426
proc url_MergePullRequestByFastForward_601590(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_MergePullRequestByFastForward_601589(path: JsonNode; query: JsonNode;
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
  var valid_601591 = header.getOrDefault("X-Amz-Date")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-Date", valid_601591
  var valid_601592 = header.getOrDefault("X-Amz-Security-Token")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "X-Amz-Security-Token", valid_601592
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601593 = header.getOrDefault("X-Amz-Target")
  valid_601593 = validateParameter(valid_601593, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestByFastForward"))
  if valid_601593 != nil:
    section.add "X-Amz-Target", valid_601593
  var valid_601594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "X-Amz-Content-Sha256", valid_601594
  var valid_601595 = header.getOrDefault("X-Amz-Algorithm")
  valid_601595 = validateParameter(valid_601595, JString, required = false,
                                 default = nil)
  if valid_601595 != nil:
    section.add "X-Amz-Algorithm", valid_601595
  var valid_601596 = header.getOrDefault("X-Amz-Signature")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "X-Amz-Signature", valid_601596
  var valid_601597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "X-Amz-SignedHeaders", valid_601597
  var valid_601598 = header.getOrDefault("X-Amz-Credential")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "X-Amz-Credential", valid_601598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601600: Call_MergePullRequestByFastForward_601588; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the fast-forward merge strategy. If the merge is successful, it closes the pull request.
  ## 
  let valid = call_601600.validator(path, query, header, formData, body)
  let scheme = call_601600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601600.url(scheme.get, call_601600.host, call_601600.base,
                         call_601600.route, valid.getOrDefault("path"))
  result = hook(call_601600, url, valid)

proc call*(call_601601: Call_MergePullRequestByFastForward_601588; body: JsonNode): Recallable =
  ## mergePullRequestByFastForward
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the fast-forward merge strategy. If the merge is successful, it closes the pull request.
  ##   body: JObject (required)
  var body_601602 = newJObject()
  if body != nil:
    body_601602 = body
  result = call_601601.call(nil, nil, nil, nil, body_601602)

var mergePullRequestByFastForward* = Call_MergePullRequestByFastForward_601588(
    name: "mergePullRequestByFastForward", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestByFastForward",
    validator: validate_MergePullRequestByFastForward_601589, base: "/",
    url: url_MergePullRequestByFastForward_601590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestBySquash_601603 = ref object of OpenApiRestCall_600426
proc url_MergePullRequestBySquash_601605(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_MergePullRequestBySquash_601604(path: JsonNode; query: JsonNode;
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
  var valid_601606 = header.getOrDefault("X-Amz-Date")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "X-Amz-Date", valid_601606
  var valid_601607 = header.getOrDefault("X-Amz-Security-Token")
  valid_601607 = validateParameter(valid_601607, JString, required = false,
                                 default = nil)
  if valid_601607 != nil:
    section.add "X-Amz-Security-Token", valid_601607
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601608 = header.getOrDefault("X-Amz-Target")
  valid_601608 = validateParameter(valid_601608, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestBySquash"))
  if valid_601608 != nil:
    section.add "X-Amz-Target", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-Content-Sha256", valid_601609
  var valid_601610 = header.getOrDefault("X-Amz-Algorithm")
  valid_601610 = validateParameter(valid_601610, JString, required = false,
                                 default = nil)
  if valid_601610 != nil:
    section.add "X-Amz-Algorithm", valid_601610
  var valid_601611 = header.getOrDefault("X-Amz-Signature")
  valid_601611 = validateParameter(valid_601611, JString, required = false,
                                 default = nil)
  if valid_601611 != nil:
    section.add "X-Amz-Signature", valid_601611
  var valid_601612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601612 = validateParameter(valid_601612, JString, required = false,
                                 default = nil)
  if valid_601612 != nil:
    section.add "X-Amz-SignedHeaders", valid_601612
  var valid_601613 = header.getOrDefault("X-Amz-Credential")
  valid_601613 = validateParameter(valid_601613, JString, required = false,
                                 default = nil)
  if valid_601613 != nil:
    section.add "X-Amz-Credential", valid_601613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601615: Call_MergePullRequestBySquash_601603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the squash merge strategy. If the merge is successful, it closes the pull request.
  ## 
  let valid = call_601615.validator(path, query, header, formData, body)
  let scheme = call_601615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601615.url(scheme.get, call_601615.host, call_601615.base,
                         call_601615.route, valid.getOrDefault("path"))
  result = hook(call_601615, url, valid)

proc call*(call_601616: Call_MergePullRequestBySquash_601603; body: JsonNode): Recallable =
  ## mergePullRequestBySquash
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the squash merge strategy. If the merge is successful, it closes the pull request.
  ##   body: JObject (required)
  var body_601617 = newJObject()
  if body != nil:
    body_601617 = body
  result = call_601616.call(nil, nil, nil, nil, body_601617)

var mergePullRequestBySquash* = Call_MergePullRequestBySquash_601603(
    name: "mergePullRequestBySquash", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestBySquash",
    validator: validate_MergePullRequestBySquash_601604, base: "/",
    url: url_MergePullRequestBySquash_601605, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestByThreeWay_601618 = ref object of OpenApiRestCall_600426
proc url_MergePullRequestByThreeWay_601620(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_MergePullRequestByThreeWay_601619(path: JsonNode; query: JsonNode;
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
  var valid_601621 = header.getOrDefault("X-Amz-Date")
  valid_601621 = validateParameter(valid_601621, JString, required = false,
                                 default = nil)
  if valid_601621 != nil:
    section.add "X-Amz-Date", valid_601621
  var valid_601622 = header.getOrDefault("X-Amz-Security-Token")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "X-Amz-Security-Token", valid_601622
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601623 = header.getOrDefault("X-Amz-Target")
  valid_601623 = validateParameter(valid_601623, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestByThreeWay"))
  if valid_601623 != nil:
    section.add "X-Amz-Target", valid_601623
  var valid_601624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-Content-Sha256", valid_601624
  var valid_601625 = header.getOrDefault("X-Amz-Algorithm")
  valid_601625 = validateParameter(valid_601625, JString, required = false,
                                 default = nil)
  if valid_601625 != nil:
    section.add "X-Amz-Algorithm", valid_601625
  var valid_601626 = header.getOrDefault("X-Amz-Signature")
  valid_601626 = validateParameter(valid_601626, JString, required = false,
                                 default = nil)
  if valid_601626 != nil:
    section.add "X-Amz-Signature", valid_601626
  var valid_601627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-SignedHeaders", valid_601627
  var valid_601628 = header.getOrDefault("X-Amz-Credential")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-Credential", valid_601628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601630: Call_MergePullRequestByThreeWay_601618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the three-way merge strategy. If the merge is successful, it closes the pull request.
  ## 
  let valid = call_601630.validator(path, query, header, formData, body)
  let scheme = call_601630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601630.url(scheme.get, call_601630.host, call_601630.base,
                         call_601630.route, valid.getOrDefault("path"))
  result = hook(call_601630, url, valid)

proc call*(call_601631: Call_MergePullRequestByThreeWay_601618; body: JsonNode): Recallable =
  ## mergePullRequestByThreeWay
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the three-way merge strategy. If the merge is successful, it closes the pull request.
  ##   body: JObject (required)
  var body_601632 = newJObject()
  if body != nil:
    body_601632 = body
  result = call_601631.call(nil, nil, nil, nil, body_601632)

var mergePullRequestByThreeWay* = Call_MergePullRequestByThreeWay_601618(
    name: "mergePullRequestByThreeWay", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestByThreeWay",
    validator: validate_MergePullRequestByThreeWay_601619, base: "/",
    url: url_MergePullRequestByThreeWay_601620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentForComparedCommit_601633 = ref object of OpenApiRestCall_600426
proc url_PostCommentForComparedCommit_601635(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCommentForComparedCommit_601634(path: JsonNode; query: JsonNode;
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
  var valid_601636 = header.getOrDefault("X-Amz-Date")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "X-Amz-Date", valid_601636
  var valid_601637 = header.getOrDefault("X-Amz-Security-Token")
  valid_601637 = validateParameter(valid_601637, JString, required = false,
                                 default = nil)
  if valid_601637 != nil:
    section.add "X-Amz-Security-Token", valid_601637
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601638 = header.getOrDefault("X-Amz-Target")
  valid_601638 = validateParameter(valid_601638, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentForComparedCommit"))
  if valid_601638 != nil:
    section.add "X-Amz-Target", valid_601638
  var valid_601639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601639 = validateParameter(valid_601639, JString, required = false,
                                 default = nil)
  if valid_601639 != nil:
    section.add "X-Amz-Content-Sha256", valid_601639
  var valid_601640 = header.getOrDefault("X-Amz-Algorithm")
  valid_601640 = validateParameter(valid_601640, JString, required = false,
                                 default = nil)
  if valid_601640 != nil:
    section.add "X-Amz-Algorithm", valid_601640
  var valid_601641 = header.getOrDefault("X-Amz-Signature")
  valid_601641 = validateParameter(valid_601641, JString, required = false,
                                 default = nil)
  if valid_601641 != nil:
    section.add "X-Amz-Signature", valid_601641
  var valid_601642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601642 = validateParameter(valid_601642, JString, required = false,
                                 default = nil)
  if valid_601642 != nil:
    section.add "X-Amz-SignedHeaders", valid_601642
  var valid_601643 = header.getOrDefault("X-Amz-Credential")
  valid_601643 = validateParameter(valid_601643, JString, required = false,
                                 default = nil)
  if valid_601643 != nil:
    section.add "X-Amz-Credential", valid_601643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601645: Call_PostCommentForComparedCommit_601633; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Posts a comment on the comparison between two commits.
  ## 
  let valid = call_601645.validator(path, query, header, formData, body)
  let scheme = call_601645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601645.url(scheme.get, call_601645.host, call_601645.base,
                         call_601645.route, valid.getOrDefault("path"))
  result = hook(call_601645, url, valid)

proc call*(call_601646: Call_PostCommentForComparedCommit_601633; body: JsonNode): Recallable =
  ## postCommentForComparedCommit
  ## Posts a comment on the comparison between two commits.
  ##   body: JObject (required)
  var body_601647 = newJObject()
  if body != nil:
    body_601647 = body
  result = call_601646.call(nil, nil, nil, nil, body_601647)

var postCommentForComparedCommit* = Call_PostCommentForComparedCommit_601633(
    name: "postCommentForComparedCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentForComparedCommit",
    validator: validate_PostCommentForComparedCommit_601634, base: "/",
    url: url_PostCommentForComparedCommit_601635,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentForPullRequest_601648 = ref object of OpenApiRestCall_600426
proc url_PostCommentForPullRequest_601650(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCommentForPullRequest_601649(path: JsonNode; query: JsonNode;
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
  var valid_601651 = header.getOrDefault("X-Amz-Date")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-Date", valid_601651
  var valid_601652 = header.getOrDefault("X-Amz-Security-Token")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-Security-Token", valid_601652
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601653 = header.getOrDefault("X-Amz-Target")
  valid_601653 = validateParameter(valid_601653, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentForPullRequest"))
  if valid_601653 != nil:
    section.add "X-Amz-Target", valid_601653
  var valid_601654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601654 = validateParameter(valid_601654, JString, required = false,
                                 default = nil)
  if valid_601654 != nil:
    section.add "X-Amz-Content-Sha256", valid_601654
  var valid_601655 = header.getOrDefault("X-Amz-Algorithm")
  valid_601655 = validateParameter(valid_601655, JString, required = false,
                                 default = nil)
  if valid_601655 != nil:
    section.add "X-Amz-Algorithm", valid_601655
  var valid_601656 = header.getOrDefault("X-Amz-Signature")
  valid_601656 = validateParameter(valid_601656, JString, required = false,
                                 default = nil)
  if valid_601656 != nil:
    section.add "X-Amz-Signature", valid_601656
  var valid_601657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601657 = validateParameter(valid_601657, JString, required = false,
                                 default = nil)
  if valid_601657 != nil:
    section.add "X-Amz-SignedHeaders", valid_601657
  var valid_601658 = header.getOrDefault("X-Amz-Credential")
  valid_601658 = validateParameter(valid_601658, JString, required = false,
                                 default = nil)
  if valid_601658 != nil:
    section.add "X-Amz-Credential", valid_601658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601660: Call_PostCommentForPullRequest_601648; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Posts a comment on a pull request.
  ## 
  let valid = call_601660.validator(path, query, header, formData, body)
  let scheme = call_601660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601660.url(scheme.get, call_601660.host, call_601660.base,
                         call_601660.route, valid.getOrDefault("path"))
  result = hook(call_601660, url, valid)

proc call*(call_601661: Call_PostCommentForPullRequest_601648; body: JsonNode): Recallable =
  ## postCommentForPullRequest
  ## Posts a comment on a pull request.
  ##   body: JObject (required)
  var body_601662 = newJObject()
  if body != nil:
    body_601662 = body
  result = call_601661.call(nil, nil, nil, nil, body_601662)

var postCommentForPullRequest* = Call_PostCommentForPullRequest_601648(
    name: "postCommentForPullRequest", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentForPullRequest",
    validator: validate_PostCommentForPullRequest_601649, base: "/",
    url: url_PostCommentForPullRequest_601650,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentReply_601663 = ref object of OpenApiRestCall_600426
proc url_PostCommentReply_601665(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCommentReply_601664(path: JsonNode; query: JsonNode;
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
  var valid_601666 = header.getOrDefault("X-Amz-Date")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "X-Amz-Date", valid_601666
  var valid_601667 = header.getOrDefault("X-Amz-Security-Token")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "X-Amz-Security-Token", valid_601667
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601668 = header.getOrDefault("X-Amz-Target")
  valid_601668 = validateParameter(valid_601668, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentReply"))
  if valid_601668 != nil:
    section.add "X-Amz-Target", valid_601668
  var valid_601669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601669 = validateParameter(valid_601669, JString, required = false,
                                 default = nil)
  if valid_601669 != nil:
    section.add "X-Amz-Content-Sha256", valid_601669
  var valid_601670 = header.getOrDefault("X-Amz-Algorithm")
  valid_601670 = validateParameter(valid_601670, JString, required = false,
                                 default = nil)
  if valid_601670 != nil:
    section.add "X-Amz-Algorithm", valid_601670
  var valid_601671 = header.getOrDefault("X-Amz-Signature")
  valid_601671 = validateParameter(valid_601671, JString, required = false,
                                 default = nil)
  if valid_601671 != nil:
    section.add "X-Amz-Signature", valid_601671
  var valid_601672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601672 = validateParameter(valid_601672, JString, required = false,
                                 default = nil)
  if valid_601672 != nil:
    section.add "X-Amz-SignedHeaders", valid_601672
  var valid_601673 = header.getOrDefault("X-Amz-Credential")
  valid_601673 = validateParameter(valid_601673, JString, required = false,
                                 default = nil)
  if valid_601673 != nil:
    section.add "X-Amz-Credential", valid_601673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601675: Call_PostCommentReply_601663; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Posts a comment in reply to an existing comment on a comparison between commits or a pull request.
  ## 
  let valid = call_601675.validator(path, query, header, formData, body)
  let scheme = call_601675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601675.url(scheme.get, call_601675.host, call_601675.base,
                         call_601675.route, valid.getOrDefault("path"))
  result = hook(call_601675, url, valid)

proc call*(call_601676: Call_PostCommentReply_601663; body: JsonNode): Recallable =
  ## postCommentReply
  ## Posts a comment in reply to an existing comment on a comparison between commits or a pull request.
  ##   body: JObject (required)
  var body_601677 = newJObject()
  if body != nil:
    body_601677 = body
  result = call_601676.call(nil, nil, nil, nil, body_601677)

var postCommentReply* = Call_PostCommentReply_601663(name: "postCommentReply",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentReply",
    validator: validate_PostCommentReply_601664, base: "/",
    url: url_PostCommentReply_601665, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFile_601678 = ref object of OpenApiRestCall_600426
proc url_PutFile_601680(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutFile_601679(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601681 = header.getOrDefault("X-Amz-Date")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "X-Amz-Date", valid_601681
  var valid_601682 = header.getOrDefault("X-Amz-Security-Token")
  valid_601682 = validateParameter(valid_601682, JString, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "X-Amz-Security-Token", valid_601682
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601683 = header.getOrDefault("X-Amz-Target")
  valid_601683 = validateParameter(valid_601683, JString, required = true, default = newJString(
      "CodeCommit_20150413.PutFile"))
  if valid_601683 != nil:
    section.add "X-Amz-Target", valid_601683
  var valid_601684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601684 = validateParameter(valid_601684, JString, required = false,
                                 default = nil)
  if valid_601684 != nil:
    section.add "X-Amz-Content-Sha256", valid_601684
  var valid_601685 = header.getOrDefault("X-Amz-Algorithm")
  valid_601685 = validateParameter(valid_601685, JString, required = false,
                                 default = nil)
  if valid_601685 != nil:
    section.add "X-Amz-Algorithm", valid_601685
  var valid_601686 = header.getOrDefault("X-Amz-Signature")
  valid_601686 = validateParameter(valid_601686, JString, required = false,
                                 default = nil)
  if valid_601686 != nil:
    section.add "X-Amz-Signature", valid_601686
  var valid_601687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601687 = validateParameter(valid_601687, JString, required = false,
                                 default = nil)
  if valid_601687 != nil:
    section.add "X-Amz-SignedHeaders", valid_601687
  var valid_601688 = header.getOrDefault("X-Amz-Credential")
  valid_601688 = validateParameter(valid_601688, JString, required = false,
                                 default = nil)
  if valid_601688 != nil:
    section.add "X-Amz-Credential", valid_601688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601690: Call_PutFile_601678; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates a file in a branch in an AWS CodeCommit repository, and generates a commit for the addition in the specified branch.
  ## 
  let valid = call_601690.validator(path, query, header, formData, body)
  let scheme = call_601690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601690.url(scheme.get, call_601690.host, call_601690.base,
                         call_601690.route, valid.getOrDefault("path"))
  result = hook(call_601690, url, valid)

proc call*(call_601691: Call_PutFile_601678; body: JsonNode): Recallable =
  ## putFile
  ## Adds or updates a file in a branch in an AWS CodeCommit repository, and generates a commit for the addition in the specified branch.
  ##   body: JObject (required)
  var body_601692 = newJObject()
  if body != nil:
    body_601692 = body
  result = call_601691.call(nil, nil, nil, nil, body_601692)

var putFile* = Call_PutFile_601678(name: "putFile", meth: HttpMethod.HttpPost,
                                host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.PutFile",
                                validator: validate_PutFile_601679, base: "/",
                                url: url_PutFile_601680,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRepositoryTriggers_601693 = ref object of OpenApiRestCall_600426
proc url_PutRepositoryTriggers_601695(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutRepositoryTriggers_601694(path: JsonNode; query: JsonNode;
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
  var valid_601696 = header.getOrDefault("X-Amz-Date")
  valid_601696 = validateParameter(valid_601696, JString, required = false,
                                 default = nil)
  if valid_601696 != nil:
    section.add "X-Amz-Date", valid_601696
  var valid_601697 = header.getOrDefault("X-Amz-Security-Token")
  valid_601697 = validateParameter(valid_601697, JString, required = false,
                                 default = nil)
  if valid_601697 != nil:
    section.add "X-Amz-Security-Token", valid_601697
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601698 = header.getOrDefault("X-Amz-Target")
  valid_601698 = validateParameter(valid_601698, JString, required = true, default = newJString(
      "CodeCommit_20150413.PutRepositoryTriggers"))
  if valid_601698 != nil:
    section.add "X-Amz-Target", valid_601698
  var valid_601699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601699 = validateParameter(valid_601699, JString, required = false,
                                 default = nil)
  if valid_601699 != nil:
    section.add "X-Amz-Content-Sha256", valid_601699
  var valid_601700 = header.getOrDefault("X-Amz-Algorithm")
  valid_601700 = validateParameter(valid_601700, JString, required = false,
                                 default = nil)
  if valid_601700 != nil:
    section.add "X-Amz-Algorithm", valid_601700
  var valid_601701 = header.getOrDefault("X-Amz-Signature")
  valid_601701 = validateParameter(valid_601701, JString, required = false,
                                 default = nil)
  if valid_601701 != nil:
    section.add "X-Amz-Signature", valid_601701
  var valid_601702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601702 = validateParameter(valid_601702, JString, required = false,
                                 default = nil)
  if valid_601702 != nil:
    section.add "X-Amz-SignedHeaders", valid_601702
  var valid_601703 = header.getOrDefault("X-Amz-Credential")
  valid_601703 = validateParameter(valid_601703, JString, required = false,
                                 default = nil)
  if valid_601703 != nil:
    section.add "X-Amz-Credential", valid_601703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601705: Call_PutRepositoryTriggers_601693; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces all triggers for a repository. This can be used to create or delete triggers.
  ## 
  let valid = call_601705.validator(path, query, header, formData, body)
  let scheme = call_601705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601705.url(scheme.get, call_601705.host, call_601705.base,
                         call_601705.route, valid.getOrDefault("path"))
  result = hook(call_601705, url, valid)

proc call*(call_601706: Call_PutRepositoryTriggers_601693; body: JsonNode): Recallable =
  ## putRepositoryTriggers
  ## Replaces all triggers for a repository. This can be used to create or delete triggers.
  ##   body: JObject (required)
  var body_601707 = newJObject()
  if body != nil:
    body_601707 = body
  result = call_601706.call(nil, nil, nil, nil, body_601707)

var putRepositoryTriggers* = Call_PutRepositoryTriggers_601693(
    name: "putRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PutRepositoryTriggers",
    validator: validate_PutRepositoryTriggers_601694, base: "/",
    url: url_PutRepositoryTriggers_601695, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601708 = ref object of OpenApiRestCall_600426
proc url_TagResource_601710(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_601709(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601711 = header.getOrDefault("X-Amz-Date")
  valid_601711 = validateParameter(valid_601711, JString, required = false,
                                 default = nil)
  if valid_601711 != nil:
    section.add "X-Amz-Date", valid_601711
  var valid_601712 = header.getOrDefault("X-Amz-Security-Token")
  valid_601712 = validateParameter(valid_601712, JString, required = false,
                                 default = nil)
  if valid_601712 != nil:
    section.add "X-Amz-Security-Token", valid_601712
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601713 = header.getOrDefault("X-Amz-Target")
  valid_601713 = validateParameter(valid_601713, JString, required = true, default = newJString(
      "CodeCommit_20150413.TagResource"))
  if valid_601713 != nil:
    section.add "X-Amz-Target", valid_601713
  var valid_601714 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601714 = validateParameter(valid_601714, JString, required = false,
                                 default = nil)
  if valid_601714 != nil:
    section.add "X-Amz-Content-Sha256", valid_601714
  var valid_601715 = header.getOrDefault("X-Amz-Algorithm")
  valid_601715 = validateParameter(valid_601715, JString, required = false,
                                 default = nil)
  if valid_601715 != nil:
    section.add "X-Amz-Algorithm", valid_601715
  var valid_601716 = header.getOrDefault("X-Amz-Signature")
  valid_601716 = validateParameter(valid_601716, JString, required = false,
                                 default = nil)
  if valid_601716 != nil:
    section.add "X-Amz-Signature", valid_601716
  var valid_601717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601717 = validateParameter(valid_601717, JString, required = false,
                                 default = nil)
  if valid_601717 != nil:
    section.add "X-Amz-SignedHeaders", valid_601717
  var valid_601718 = header.getOrDefault("X-Amz-Credential")
  valid_601718 = validateParameter(valid_601718, JString, required = false,
                                 default = nil)
  if valid_601718 != nil:
    section.add "X-Amz-Credential", valid_601718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601720: Call_TagResource_601708; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ## 
  let valid = call_601720.validator(path, query, header, formData, body)
  let scheme = call_601720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601720.url(scheme.get, call_601720.host, call_601720.base,
                         call_601720.route, valid.getOrDefault("path"))
  result = hook(call_601720, url, valid)

proc call*(call_601721: Call_TagResource_601708; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ##   body: JObject (required)
  var body_601722 = newJObject()
  if body != nil:
    body_601722 = body
  result = call_601721.call(nil, nil, nil, nil, body_601722)

var tagResource* = Call_TagResource_601708(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.TagResource",
                                        validator: validate_TagResource_601709,
                                        base: "/", url: url_TagResource_601710,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestRepositoryTriggers_601723 = ref object of OpenApiRestCall_600426
proc url_TestRepositoryTriggers_601725(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TestRepositoryTriggers_601724(path: JsonNode; query: JsonNode;
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
  var valid_601726 = header.getOrDefault("X-Amz-Date")
  valid_601726 = validateParameter(valid_601726, JString, required = false,
                                 default = nil)
  if valid_601726 != nil:
    section.add "X-Amz-Date", valid_601726
  var valid_601727 = header.getOrDefault("X-Amz-Security-Token")
  valid_601727 = validateParameter(valid_601727, JString, required = false,
                                 default = nil)
  if valid_601727 != nil:
    section.add "X-Amz-Security-Token", valid_601727
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601728 = header.getOrDefault("X-Amz-Target")
  valid_601728 = validateParameter(valid_601728, JString, required = true, default = newJString(
      "CodeCommit_20150413.TestRepositoryTriggers"))
  if valid_601728 != nil:
    section.add "X-Amz-Target", valid_601728
  var valid_601729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601729 = validateParameter(valid_601729, JString, required = false,
                                 default = nil)
  if valid_601729 != nil:
    section.add "X-Amz-Content-Sha256", valid_601729
  var valid_601730 = header.getOrDefault("X-Amz-Algorithm")
  valid_601730 = validateParameter(valid_601730, JString, required = false,
                                 default = nil)
  if valid_601730 != nil:
    section.add "X-Amz-Algorithm", valid_601730
  var valid_601731 = header.getOrDefault("X-Amz-Signature")
  valid_601731 = validateParameter(valid_601731, JString, required = false,
                                 default = nil)
  if valid_601731 != nil:
    section.add "X-Amz-Signature", valid_601731
  var valid_601732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601732 = validateParameter(valid_601732, JString, required = false,
                                 default = nil)
  if valid_601732 != nil:
    section.add "X-Amz-SignedHeaders", valid_601732
  var valid_601733 = header.getOrDefault("X-Amz-Credential")
  valid_601733 = validateParameter(valid_601733, JString, required = false,
                                 default = nil)
  if valid_601733 != nil:
    section.add "X-Amz-Credential", valid_601733
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601735: Call_TestRepositoryTriggers_601723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tests the functionality of repository triggers by sending information to the trigger target. If real data is available in the repository, the test will send data from the last commit. If no data is available, sample data will be generated.
  ## 
  let valid = call_601735.validator(path, query, header, formData, body)
  let scheme = call_601735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601735.url(scheme.get, call_601735.host, call_601735.base,
                         call_601735.route, valid.getOrDefault("path"))
  result = hook(call_601735, url, valid)

proc call*(call_601736: Call_TestRepositoryTriggers_601723; body: JsonNode): Recallable =
  ## testRepositoryTriggers
  ## Tests the functionality of repository triggers by sending information to the trigger target. If real data is available in the repository, the test will send data from the last commit. If no data is available, sample data will be generated.
  ##   body: JObject (required)
  var body_601737 = newJObject()
  if body != nil:
    body_601737 = body
  result = call_601736.call(nil, nil, nil, nil, body_601737)

var testRepositoryTriggers* = Call_TestRepositoryTriggers_601723(
    name: "testRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.TestRepositoryTriggers",
    validator: validate_TestRepositoryTriggers_601724, base: "/",
    url: url_TestRepositoryTriggers_601725, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601738 = ref object of OpenApiRestCall_600426
proc url_UntagResource_601740(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_601739(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601741 = header.getOrDefault("X-Amz-Date")
  valid_601741 = validateParameter(valid_601741, JString, required = false,
                                 default = nil)
  if valid_601741 != nil:
    section.add "X-Amz-Date", valid_601741
  var valid_601742 = header.getOrDefault("X-Amz-Security-Token")
  valid_601742 = validateParameter(valid_601742, JString, required = false,
                                 default = nil)
  if valid_601742 != nil:
    section.add "X-Amz-Security-Token", valid_601742
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601743 = header.getOrDefault("X-Amz-Target")
  valid_601743 = validateParameter(valid_601743, JString, required = true, default = newJString(
      "CodeCommit_20150413.UntagResource"))
  if valid_601743 != nil:
    section.add "X-Amz-Target", valid_601743
  var valid_601744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601744 = validateParameter(valid_601744, JString, required = false,
                                 default = nil)
  if valid_601744 != nil:
    section.add "X-Amz-Content-Sha256", valid_601744
  var valid_601745 = header.getOrDefault("X-Amz-Algorithm")
  valid_601745 = validateParameter(valid_601745, JString, required = false,
                                 default = nil)
  if valid_601745 != nil:
    section.add "X-Amz-Algorithm", valid_601745
  var valid_601746 = header.getOrDefault("X-Amz-Signature")
  valid_601746 = validateParameter(valid_601746, JString, required = false,
                                 default = nil)
  if valid_601746 != nil:
    section.add "X-Amz-Signature", valid_601746
  var valid_601747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601747 = validateParameter(valid_601747, JString, required = false,
                                 default = nil)
  if valid_601747 != nil:
    section.add "X-Amz-SignedHeaders", valid_601747
  var valid_601748 = header.getOrDefault("X-Amz-Credential")
  valid_601748 = validateParameter(valid_601748, JString, required = false,
                                 default = nil)
  if valid_601748 != nil:
    section.add "X-Amz-Credential", valid_601748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601750: Call_UntagResource_601738; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ## 
  let valid = call_601750.validator(path, query, header, formData, body)
  let scheme = call_601750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601750.url(scheme.get, call_601750.host, call_601750.base,
                         call_601750.route, valid.getOrDefault("path"))
  result = hook(call_601750, url, valid)

proc call*(call_601751: Call_UntagResource_601738; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ##   body: JObject (required)
  var body_601752 = newJObject()
  if body != nil:
    body_601752 = body
  result = call_601751.call(nil, nil, nil, nil, body_601752)

var untagResource* = Call_UntagResource_601738(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UntagResource",
    validator: validate_UntagResource_601739, base: "/", url: url_UntagResource_601740,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateComment_601753 = ref object of OpenApiRestCall_600426
proc url_UpdateComment_601755(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateComment_601754(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601756 = header.getOrDefault("X-Amz-Date")
  valid_601756 = validateParameter(valid_601756, JString, required = false,
                                 default = nil)
  if valid_601756 != nil:
    section.add "X-Amz-Date", valid_601756
  var valid_601757 = header.getOrDefault("X-Amz-Security-Token")
  valid_601757 = validateParameter(valid_601757, JString, required = false,
                                 default = nil)
  if valid_601757 != nil:
    section.add "X-Amz-Security-Token", valid_601757
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601758 = header.getOrDefault("X-Amz-Target")
  valid_601758 = validateParameter(valid_601758, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateComment"))
  if valid_601758 != nil:
    section.add "X-Amz-Target", valid_601758
  var valid_601759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601759 = validateParameter(valid_601759, JString, required = false,
                                 default = nil)
  if valid_601759 != nil:
    section.add "X-Amz-Content-Sha256", valid_601759
  var valid_601760 = header.getOrDefault("X-Amz-Algorithm")
  valid_601760 = validateParameter(valid_601760, JString, required = false,
                                 default = nil)
  if valid_601760 != nil:
    section.add "X-Amz-Algorithm", valid_601760
  var valid_601761 = header.getOrDefault("X-Amz-Signature")
  valid_601761 = validateParameter(valid_601761, JString, required = false,
                                 default = nil)
  if valid_601761 != nil:
    section.add "X-Amz-Signature", valid_601761
  var valid_601762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601762 = validateParameter(valid_601762, JString, required = false,
                                 default = nil)
  if valid_601762 != nil:
    section.add "X-Amz-SignedHeaders", valid_601762
  var valid_601763 = header.getOrDefault("X-Amz-Credential")
  valid_601763 = validateParameter(valid_601763, JString, required = false,
                                 default = nil)
  if valid_601763 != nil:
    section.add "X-Amz-Credential", valid_601763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601765: Call_UpdateComment_601753; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the contents of a comment.
  ## 
  let valid = call_601765.validator(path, query, header, formData, body)
  let scheme = call_601765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601765.url(scheme.get, call_601765.host, call_601765.base,
                         call_601765.route, valid.getOrDefault("path"))
  result = hook(call_601765, url, valid)

proc call*(call_601766: Call_UpdateComment_601753; body: JsonNode): Recallable =
  ## updateComment
  ## Replaces the contents of a comment.
  ##   body: JObject (required)
  var body_601767 = newJObject()
  if body != nil:
    body_601767 = body
  result = call_601766.call(nil, nil, nil, nil, body_601767)

var updateComment* = Call_UpdateComment_601753(name: "updateComment",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateComment",
    validator: validate_UpdateComment_601754, base: "/", url: url_UpdateComment_601755,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDefaultBranch_601768 = ref object of OpenApiRestCall_600426
proc url_UpdateDefaultBranch_601770(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDefaultBranch_601769(path: JsonNode; query: JsonNode;
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
  var valid_601771 = header.getOrDefault("X-Amz-Date")
  valid_601771 = validateParameter(valid_601771, JString, required = false,
                                 default = nil)
  if valid_601771 != nil:
    section.add "X-Amz-Date", valid_601771
  var valid_601772 = header.getOrDefault("X-Amz-Security-Token")
  valid_601772 = validateParameter(valid_601772, JString, required = false,
                                 default = nil)
  if valid_601772 != nil:
    section.add "X-Amz-Security-Token", valid_601772
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601773 = header.getOrDefault("X-Amz-Target")
  valid_601773 = validateParameter(valid_601773, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateDefaultBranch"))
  if valid_601773 != nil:
    section.add "X-Amz-Target", valid_601773
  var valid_601774 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601774 = validateParameter(valid_601774, JString, required = false,
                                 default = nil)
  if valid_601774 != nil:
    section.add "X-Amz-Content-Sha256", valid_601774
  var valid_601775 = header.getOrDefault("X-Amz-Algorithm")
  valid_601775 = validateParameter(valid_601775, JString, required = false,
                                 default = nil)
  if valid_601775 != nil:
    section.add "X-Amz-Algorithm", valid_601775
  var valid_601776 = header.getOrDefault("X-Amz-Signature")
  valid_601776 = validateParameter(valid_601776, JString, required = false,
                                 default = nil)
  if valid_601776 != nil:
    section.add "X-Amz-Signature", valid_601776
  var valid_601777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601777 = validateParameter(valid_601777, JString, required = false,
                                 default = nil)
  if valid_601777 != nil:
    section.add "X-Amz-SignedHeaders", valid_601777
  var valid_601778 = header.getOrDefault("X-Amz-Credential")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "X-Amz-Credential", valid_601778
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601780: Call_UpdateDefaultBranch_601768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or changes the default branch name for the specified repository.</p> <note> <p>If you use this operation to change the default branch name to the current default branch name, a success message is returned even though the default branch did not change.</p> </note>
  ## 
  let valid = call_601780.validator(path, query, header, formData, body)
  let scheme = call_601780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601780.url(scheme.get, call_601780.host, call_601780.base,
                         call_601780.route, valid.getOrDefault("path"))
  result = hook(call_601780, url, valid)

proc call*(call_601781: Call_UpdateDefaultBranch_601768; body: JsonNode): Recallable =
  ## updateDefaultBranch
  ## <p>Sets or changes the default branch name for the specified repository.</p> <note> <p>If you use this operation to change the default branch name to the current default branch name, a success message is returned even though the default branch did not change.</p> </note>
  ##   body: JObject (required)
  var body_601782 = newJObject()
  if body != nil:
    body_601782 = body
  result = call_601781.call(nil, nil, nil, nil, body_601782)

var updateDefaultBranch* = Call_UpdateDefaultBranch_601768(
    name: "updateDefaultBranch", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateDefaultBranch",
    validator: validate_UpdateDefaultBranch_601769, base: "/",
    url: url_UpdateDefaultBranch_601770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestDescription_601783 = ref object of OpenApiRestCall_600426
proc url_UpdatePullRequestDescription_601785(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdatePullRequestDescription_601784(path: JsonNode; query: JsonNode;
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
  var valid_601786 = header.getOrDefault("X-Amz-Date")
  valid_601786 = validateParameter(valid_601786, JString, required = false,
                                 default = nil)
  if valid_601786 != nil:
    section.add "X-Amz-Date", valid_601786
  var valid_601787 = header.getOrDefault("X-Amz-Security-Token")
  valid_601787 = validateParameter(valid_601787, JString, required = false,
                                 default = nil)
  if valid_601787 != nil:
    section.add "X-Amz-Security-Token", valid_601787
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601788 = header.getOrDefault("X-Amz-Target")
  valid_601788 = validateParameter(valid_601788, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestDescription"))
  if valid_601788 != nil:
    section.add "X-Amz-Target", valid_601788
  var valid_601789 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601789 = validateParameter(valid_601789, JString, required = false,
                                 default = nil)
  if valid_601789 != nil:
    section.add "X-Amz-Content-Sha256", valid_601789
  var valid_601790 = header.getOrDefault("X-Amz-Algorithm")
  valid_601790 = validateParameter(valid_601790, JString, required = false,
                                 default = nil)
  if valid_601790 != nil:
    section.add "X-Amz-Algorithm", valid_601790
  var valid_601791 = header.getOrDefault("X-Amz-Signature")
  valid_601791 = validateParameter(valid_601791, JString, required = false,
                                 default = nil)
  if valid_601791 != nil:
    section.add "X-Amz-Signature", valid_601791
  var valid_601792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601792 = validateParameter(valid_601792, JString, required = false,
                                 default = nil)
  if valid_601792 != nil:
    section.add "X-Amz-SignedHeaders", valid_601792
  var valid_601793 = header.getOrDefault("X-Amz-Credential")
  valid_601793 = validateParameter(valid_601793, JString, required = false,
                                 default = nil)
  if valid_601793 != nil:
    section.add "X-Amz-Credential", valid_601793
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601795: Call_UpdatePullRequestDescription_601783; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the contents of the description of a pull request.
  ## 
  let valid = call_601795.validator(path, query, header, formData, body)
  let scheme = call_601795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601795.url(scheme.get, call_601795.host, call_601795.base,
                         call_601795.route, valid.getOrDefault("path"))
  result = hook(call_601795, url, valid)

proc call*(call_601796: Call_UpdatePullRequestDescription_601783; body: JsonNode): Recallable =
  ## updatePullRequestDescription
  ## Replaces the contents of the description of a pull request.
  ##   body: JObject (required)
  var body_601797 = newJObject()
  if body != nil:
    body_601797 = body
  result = call_601796.call(nil, nil, nil, nil, body_601797)

var updatePullRequestDescription* = Call_UpdatePullRequestDescription_601783(
    name: "updatePullRequestDescription", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestDescription",
    validator: validate_UpdatePullRequestDescription_601784, base: "/",
    url: url_UpdatePullRequestDescription_601785,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestStatus_601798 = ref object of OpenApiRestCall_600426
proc url_UpdatePullRequestStatus_601800(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdatePullRequestStatus_601799(path: JsonNode; query: JsonNode;
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
  var valid_601801 = header.getOrDefault("X-Amz-Date")
  valid_601801 = validateParameter(valid_601801, JString, required = false,
                                 default = nil)
  if valid_601801 != nil:
    section.add "X-Amz-Date", valid_601801
  var valid_601802 = header.getOrDefault("X-Amz-Security-Token")
  valid_601802 = validateParameter(valid_601802, JString, required = false,
                                 default = nil)
  if valid_601802 != nil:
    section.add "X-Amz-Security-Token", valid_601802
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601803 = header.getOrDefault("X-Amz-Target")
  valid_601803 = validateParameter(valid_601803, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestStatus"))
  if valid_601803 != nil:
    section.add "X-Amz-Target", valid_601803
  var valid_601804 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601804 = validateParameter(valid_601804, JString, required = false,
                                 default = nil)
  if valid_601804 != nil:
    section.add "X-Amz-Content-Sha256", valid_601804
  var valid_601805 = header.getOrDefault("X-Amz-Algorithm")
  valid_601805 = validateParameter(valid_601805, JString, required = false,
                                 default = nil)
  if valid_601805 != nil:
    section.add "X-Amz-Algorithm", valid_601805
  var valid_601806 = header.getOrDefault("X-Amz-Signature")
  valid_601806 = validateParameter(valid_601806, JString, required = false,
                                 default = nil)
  if valid_601806 != nil:
    section.add "X-Amz-Signature", valid_601806
  var valid_601807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601807 = validateParameter(valid_601807, JString, required = false,
                                 default = nil)
  if valid_601807 != nil:
    section.add "X-Amz-SignedHeaders", valid_601807
  var valid_601808 = header.getOrDefault("X-Amz-Credential")
  valid_601808 = validateParameter(valid_601808, JString, required = false,
                                 default = nil)
  if valid_601808 != nil:
    section.add "X-Amz-Credential", valid_601808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601810: Call_UpdatePullRequestStatus_601798; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of a pull request. 
  ## 
  let valid = call_601810.validator(path, query, header, formData, body)
  let scheme = call_601810.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601810.url(scheme.get, call_601810.host, call_601810.base,
                         call_601810.route, valid.getOrDefault("path"))
  result = hook(call_601810, url, valid)

proc call*(call_601811: Call_UpdatePullRequestStatus_601798; body: JsonNode): Recallable =
  ## updatePullRequestStatus
  ## Updates the status of a pull request. 
  ##   body: JObject (required)
  var body_601812 = newJObject()
  if body != nil:
    body_601812 = body
  result = call_601811.call(nil, nil, nil, nil, body_601812)

var updatePullRequestStatus* = Call_UpdatePullRequestStatus_601798(
    name: "updatePullRequestStatus", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestStatus",
    validator: validate_UpdatePullRequestStatus_601799, base: "/",
    url: url_UpdatePullRequestStatus_601800, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestTitle_601813 = ref object of OpenApiRestCall_600426
proc url_UpdatePullRequestTitle_601815(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdatePullRequestTitle_601814(path: JsonNode; query: JsonNode;
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
  var valid_601816 = header.getOrDefault("X-Amz-Date")
  valid_601816 = validateParameter(valid_601816, JString, required = false,
                                 default = nil)
  if valid_601816 != nil:
    section.add "X-Amz-Date", valid_601816
  var valid_601817 = header.getOrDefault("X-Amz-Security-Token")
  valid_601817 = validateParameter(valid_601817, JString, required = false,
                                 default = nil)
  if valid_601817 != nil:
    section.add "X-Amz-Security-Token", valid_601817
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601818 = header.getOrDefault("X-Amz-Target")
  valid_601818 = validateParameter(valid_601818, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestTitle"))
  if valid_601818 != nil:
    section.add "X-Amz-Target", valid_601818
  var valid_601819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601819 = validateParameter(valid_601819, JString, required = false,
                                 default = nil)
  if valid_601819 != nil:
    section.add "X-Amz-Content-Sha256", valid_601819
  var valid_601820 = header.getOrDefault("X-Amz-Algorithm")
  valid_601820 = validateParameter(valid_601820, JString, required = false,
                                 default = nil)
  if valid_601820 != nil:
    section.add "X-Amz-Algorithm", valid_601820
  var valid_601821 = header.getOrDefault("X-Amz-Signature")
  valid_601821 = validateParameter(valid_601821, JString, required = false,
                                 default = nil)
  if valid_601821 != nil:
    section.add "X-Amz-Signature", valid_601821
  var valid_601822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601822 = validateParameter(valid_601822, JString, required = false,
                                 default = nil)
  if valid_601822 != nil:
    section.add "X-Amz-SignedHeaders", valid_601822
  var valid_601823 = header.getOrDefault("X-Amz-Credential")
  valid_601823 = validateParameter(valid_601823, JString, required = false,
                                 default = nil)
  if valid_601823 != nil:
    section.add "X-Amz-Credential", valid_601823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601825: Call_UpdatePullRequestTitle_601813; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the title of a pull request.
  ## 
  let valid = call_601825.validator(path, query, header, formData, body)
  let scheme = call_601825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601825.url(scheme.get, call_601825.host, call_601825.base,
                         call_601825.route, valid.getOrDefault("path"))
  result = hook(call_601825, url, valid)

proc call*(call_601826: Call_UpdatePullRequestTitle_601813; body: JsonNode): Recallable =
  ## updatePullRequestTitle
  ## Replaces the title of a pull request.
  ##   body: JObject (required)
  var body_601827 = newJObject()
  if body != nil:
    body_601827 = body
  result = call_601826.call(nil, nil, nil, nil, body_601827)

var updatePullRequestTitle* = Call_UpdatePullRequestTitle_601813(
    name: "updatePullRequestTitle", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestTitle",
    validator: validate_UpdatePullRequestTitle_601814, base: "/",
    url: url_UpdatePullRequestTitle_601815, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRepositoryDescription_601828 = ref object of OpenApiRestCall_600426
proc url_UpdateRepositoryDescription_601830(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateRepositoryDescription_601829(path: JsonNode; query: JsonNode;
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
  var valid_601831 = header.getOrDefault("X-Amz-Date")
  valid_601831 = validateParameter(valid_601831, JString, required = false,
                                 default = nil)
  if valid_601831 != nil:
    section.add "X-Amz-Date", valid_601831
  var valid_601832 = header.getOrDefault("X-Amz-Security-Token")
  valid_601832 = validateParameter(valid_601832, JString, required = false,
                                 default = nil)
  if valid_601832 != nil:
    section.add "X-Amz-Security-Token", valid_601832
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601833 = header.getOrDefault("X-Amz-Target")
  valid_601833 = validateParameter(valid_601833, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateRepositoryDescription"))
  if valid_601833 != nil:
    section.add "X-Amz-Target", valid_601833
  var valid_601834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601834 = validateParameter(valid_601834, JString, required = false,
                                 default = nil)
  if valid_601834 != nil:
    section.add "X-Amz-Content-Sha256", valid_601834
  var valid_601835 = header.getOrDefault("X-Amz-Algorithm")
  valid_601835 = validateParameter(valid_601835, JString, required = false,
                                 default = nil)
  if valid_601835 != nil:
    section.add "X-Amz-Algorithm", valid_601835
  var valid_601836 = header.getOrDefault("X-Amz-Signature")
  valid_601836 = validateParameter(valid_601836, JString, required = false,
                                 default = nil)
  if valid_601836 != nil:
    section.add "X-Amz-Signature", valid_601836
  var valid_601837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601837 = validateParameter(valid_601837, JString, required = false,
                                 default = nil)
  if valid_601837 != nil:
    section.add "X-Amz-SignedHeaders", valid_601837
  var valid_601838 = header.getOrDefault("X-Amz-Credential")
  valid_601838 = validateParameter(valid_601838, JString, required = false,
                                 default = nil)
  if valid_601838 != nil:
    section.add "X-Amz-Credential", valid_601838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601840: Call_UpdateRepositoryDescription_601828; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or changes the comment or description for a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ## 
  let valid = call_601840.validator(path, query, header, formData, body)
  let scheme = call_601840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601840.url(scheme.get, call_601840.host, call_601840.base,
                         call_601840.route, valid.getOrDefault("path"))
  result = hook(call_601840, url, valid)

proc call*(call_601841: Call_UpdateRepositoryDescription_601828; body: JsonNode): Recallable =
  ## updateRepositoryDescription
  ## <p>Sets or changes the comment or description for a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ##   body: JObject (required)
  var body_601842 = newJObject()
  if body != nil:
    body_601842 = body
  result = call_601841.call(nil, nil, nil, nil, body_601842)

var updateRepositoryDescription* = Call_UpdateRepositoryDescription_601828(
    name: "updateRepositoryDescription", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateRepositoryDescription",
    validator: validate_UpdateRepositoryDescription_601829, base: "/",
    url: url_UpdateRepositoryDescription_601830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRepositoryName_601843 = ref object of OpenApiRestCall_600426
proc url_UpdateRepositoryName_601845(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateRepositoryName_601844(path: JsonNode; query: JsonNode;
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
  var valid_601846 = header.getOrDefault("X-Amz-Date")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Date", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Security-Token")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Security-Token", valid_601847
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601848 = header.getOrDefault("X-Amz-Target")
  valid_601848 = validateParameter(valid_601848, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateRepositoryName"))
  if valid_601848 != nil:
    section.add "X-Amz-Target", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-Content-Sha256", valid_601849
  var valid_601850 = header.getOrDefault("X-Amz-Algorithm")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Algorithm", valid_601850
  var valid_601851 = header.getOrDefault("X-Amz-Signature")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "X-Amz-Signature", valid_601851
  var valid_601852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601852 = validateParameter(valid_601852, JString, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "X-Amz-SignedHeaders", valid_601852
  var valid_601853 = header.getOrDefault("X-Amz-Credential")
  valid_601853 = validateParameter(valid_601853, JString, required = false,
                                 default = nil)
  if valid_601853 != nil:
    section.add "X-Amz-Credential", valid_601853
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601855: Call_UpdateRepositoryName_601843; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Renames a repository. The repository name must be unique across the calling AWS account. In addition, repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. The suffix ".git" is prohibited. For a full description of the limits on repository names, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html">Limits</a> in the AWS CodeCommit User Guide.
  ## 
  let valid = call_601855.validator(path, query, header, formData, body)
  let scheme = call_601855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601855.url(scheme.get, call_601855.host, call_601855.base,
                         call_601855.route, valid.getOrDefault("path"))
  result = hook(call_601855, url, valid)

proc call*(call_601856: Call_UpdateRepositoryName_601843; body: JsonNode): Recallable =
  ## updateRepositoryName
  ## Renames a repository. The repository name must be unique across the calling AWS account. In addition, repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. The suffix ".git" is prohibited. For a full description of the limits on repository names, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html">Limits</a> in the AWS CodeCommit User Guide.
  ##   body: JObject (required)
  var body_601857 = newJObject()
  if body != nil:
    body_601857 = body
  result = call_601856.call(nil, nil, nil, nil, body_601857)

var updateRepositoryName* = Call_UpdateRepositoryName_601843(
    name: "updateRepositoryName", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateRepositoryName",
    validator: validate_UpdateRepositoryName_601844, base: "/",
    url: url_UpdateRepositoryName_601845, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
