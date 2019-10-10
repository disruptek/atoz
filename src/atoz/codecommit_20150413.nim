
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
  Call_BatchDescribeMergeConflicts_602803 = ref object of OpenApiRestCall_602466
proc url_BatchDescribeMergeConflicts_602805(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDescribeMergeConflicts_602804(path: JsonNode; query: JsonNode;
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
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchDescribeMergeConflicts"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_BatchDescribeMergeConflicts_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy.
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_BatchDescribeMergeConflicts_602803; body: JsonNode): Recallable =
  ## batchDescribeMergeConflicts
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy.
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var batchDescribeMergeConflicts* = Call_BatchDescribeMergeConflicts_602803(
    name: "batchDescribeMergeConflicts", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchDescribeMergeConflicts",
    validator: validate_BatchDescribeMergeConflicts_602804, base: "/",
    url: url_BatchDescribeMergeConflicts_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetCommits_603072 = ref object of OpenApiRestCall_602466
proc url_BatchGetCommits_603074(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetCommits_603073(path: JsonNode; query: JsonNode;
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
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchGetCommits"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_BatchGetCommits_603072; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the contents of one or more commits in a repository.
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_BatchGetCommits_603072; body: JsonNode): Recallable =
  ## batchGetCommits
  ## Returns information about the contents of one or more commits in a repository.
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var batchGetCommits* = Call_BatchGetCommits_603072(name: "batchGetCommits",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchGetCommits",
    validator: validate_BatchGetCommits_603073, base: "/", url: url_BatchGetCommits_603074,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetRepositories_603087 = ref object of OpenApiRestCall_602466
proc url_BatchGetRepositories_603089(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetRepositories_603088(path: JsonNode; query: JsonNode;
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
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchGetRepositories"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_BatchGetRepositories_603087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about one or more repositories.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_BatchGetRepositories_603087; body: JsonNode): Recallable =
  ## batchGetRepositories
  ## <p>Returns information about one or more repositories.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var batchGetRepositories* = Call_BatchGetRepositories_603087(
    name: "batchGetRepositories", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchGetRepositories",
    validator: validate_BatchGetRepositories_603088, base: "/",
    url: url_BatchGetRepositories_603089, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBranch_603102 = ref object of OpenApiRestCall_602466
proc url_CreateBranch_603104(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateBranch_603103(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateBranch"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_CreateBranch_603102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new branch in a repository and points the branch to a commit.</p> <note> <p>Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.</p> </note>
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_CreateBranch_603102; body: JsonNode): Recallable =
  ## createBranch
  ## <p>Creates a new branch in a repository and points the branch to a commit.</p> <note> <p>Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.</p> </note>
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var createBranch* = Call_CreateBranch_603102(name: "createBranch",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateBranch",
    validator: validate_CreateBranch_603103, base: "/", url: url_CreateBranch_603104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCommit_603117 = ref object of OpenApiRestCall_602466
proc url_CreateCommit_603119(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCommit_603118(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateCommit"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_CreateCommit_603117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a commit for a repository on the tip of a specified branch.
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_CreateCommit_603117; body: JsonNode): Recallable =
  ## createCommit
  ## Creates a commit for a repository on the tip of a specified branch.
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var createCommit* = Call_CreateCommit_603117(name: "createCommit",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateCommit",
    validator: validate_CreateCommit_603118, base: "/", url: url_CreateCommit_603119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePullRequest_603132 = ref object of OpenApiRestCall_602466
proc url_CreatePullRequest_603134(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreatePullRequest_603133(path: JsonNode; query: JsonNode;
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
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreatePullRequest"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_CreatePullRequest_603132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a pull request in the specified repository.
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_CreatePullRequest_603132; body: JsonNode): Recallable =
  ## createPullRequest
  ## Creates a pull request in the specified repository.
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var createPullRequest* = Call_CreatePullRequest_603132(name: "createPullRequest",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreatePullRequest",
    validator: validate_CreatePullRequest_603133, base: "/",
    url: url_CreatePullRequest_603134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRepository_603147 = ref object of OpenApiRestCall_602466
proc url_CreateRepository_603149(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRepository_603148(path: JsonNode; query: JsonNode;
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
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Security-Token")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Security-Token", valid_603151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603152 = header.getOrDefault("X-Amz-Target")
  valid_603152 = validateParameter(valid_603152, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateRepository"))
  if valid_603152 != nil:
    section.add "X-Amz-Target", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Algorithm")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Algorithm", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-SignedHeaders", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Credential")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Credential", valid_603157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_CreateRepository_603147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new, empty repository.
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_CreateRepository_603147; body: JsonNode): Recallable =
  ## createRepository
  ## Creates a new, empty repository.
  ##   body: JObject (required)
  var body_603161 = newJObject()
  if body != nil:
    body_603161 = body
  result = call_603160.call(nil, nil, nil, nil, body_603161)

var createRepository* = Call_CreateRepository_603147(name: "createRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateRepository",
    validator: validate_CreateRepository_603148, base: "/",
    url: url_CreateRepository_603149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUnreferencedMergeCommit_603162 = ref object of OpenApiRestCall_602466
proc url_CreateUnreferencedMergeCommit_603164(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateUnreferencedMergeCommit_603163(path: JsonNode; query: JsonNode;
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
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Security-Token")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Security-Token", valid_603166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateUnreferencedMergeCommit"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Content-Sha256", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Algorithm")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Algorithm", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Signature")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Signature", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-SignedHeaders", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Credential")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Credential", valid_603172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_CreateUnreferencedMergeCommit_603162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an unreferenced commit that represents the result of merging two branches using a specified merge strategy. This can help you determine the outcome of a potential merge. This API cannot be used with the fast-forward merge strategy, as that strategy does not create a merge commit.</p> <note> <p>This unreferenced merge commit can only be accessed using the GetCommit API or through git commands such as git fetch. To retrieve this commit, you must specify its commit ID or otherwise reference it.</p> </note>
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_CreateUnreferencedMergeCommit_603162; body: JsonNode): Recallable =
  ## createUnreferencedMergeCommit
  ## <p>Creates an unreferenced commit that represents the result of merging two branches using a specified merge strategy. This can help you determine the outcome of a potential merge. This API cannot be used with the fast-forward merge strategy, as that strategy does not create a merge commit.</p> <note> <p>This unreferenced merge commit can only be accessed using the GetCommit API or through git commands such as git fetch. To retrieve this commit, you must specify its commit ID or otherwise reference it.</p> </note>
  ##   body: JObject (required)
  var body_603176 = newJObject()
  if body != nil:
    body_603176 = body
  result = call_603175.call(nil, nil, nil, nil, body_603176)

var createUnreferencedMergeCommit* = Call_CreateUnreferencedMergeCommit_603162(
    name: "createUnreferencedMergeCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateUnreferencedMergeCommit",
    validator: validate_CreateUnreferencedMergeCommit_603163, base: "/",
    url: url_CreateUnreferencedMergeCommit_603164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBranch_603177 = ref object of OpenApiRestCall_602466
proc url_DeleteBranch_603179(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteBranch_603178(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteBranch"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Content-Sha256", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Algorithm")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Algorithm", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Credential")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Credential", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_DeleteBranch_603177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a branch from a repository, unless that branch is the default branch for the repository. 
  ## 
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_DeleteBranch_603177; body: JsonNode): Recallable =
  ## deleteBranch
  ## Deletes a branch from a repository, unless that branch is the default branch for the repository. 
  ##   body: JObject (required)
  var body_603191 = newJObject()
  if body != nil:
    body_603191 = body
  result = call_603190.call(nil, nil, nil, nil, body_603191)

var deleteBranch* = Call_DeleteBranch_603177(name: "deleteBranch",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteBranch",
    validator: validate_DeleteBranch_603178, base: "/", url: url_DeleteBranch_603179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCommentContent_603192 = ref object of OpenApiRestCall_602466
proc url_DeleteCommentContent_603194(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteCommentContent_603193(path: JsonNode; query: JsonNode;
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
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603197 = header.getOrDefault("X-Amz-Target")
  valid_603197 = validateParameter(valid_603197, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteCommentContent"))
  if valid_603197 != nil:
    section.add "X-Amz-Target", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Content-Sha256", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Algorithm")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Algorithm", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-SignedHeaders", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Credential")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Credential", valid_603202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_DeleteCommentContent_603192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the content of a comment made on a change, file, or commit in a repository.
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_DeleteCommentContent_603192; body: JsonNode): Recallable =
  ## deleteCommentContent
  ## Deletes the content of a comment made on a change, file, or commit in a repository.
  ##   body: JObject (required)
  var body_603206 = newJObject()
  if body != nil:
    body_603206 = body
  result = call_603205.call(nil, nil, nil, nil, body_603206)

var deleteCommentContent* = Call_DeleteCommentContent_603192(
    name: "deleteCommentContent", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteCommentContent",
    validator: validate_DeleteCommentContent_603193, base: "/",
    url: url_DeleteCommentContent_603194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFile_603207 = ref object of OpenApiRestCall_602466
proc url_DeleteFile_603209(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteFile_603208(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603212 = header.getOrDefault("X-Amz-Target")
  valid_603212 = validateParameter(valid_603212, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteFile"))
  if valid_603212 != nil:
    section.add "X-Amz-Target", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Content-Sha256", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Algorithm")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Algorithm", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-SignedHeaders", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Credential")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Credential", valid_603217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603219: Call_DeleteFile_603207; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified file from a specified branch. A commit is created on the branch that contains the revision. The file will still exist in the commits prior to the commit that contains the deletion.
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603219, url, valid)

proc call*(call_603220: Call_DeleteFile_603207; body: JsonNode): Recallable =
  ## deleteFile
  ## Deletes a specified file from a specified branch. A commit is created on the branch that contains the revision. The file will still exist in the commits prior to the commit that contains the deletion.
  ##   body: JObject (required)
  var body_603221 = newJObject()
  if body != nil:
    body_603221 = body
  result = call_603220.call(nil, nil, nil, nil, body_603221)

var deleteFile* = Call_DeleteFile_603207(name: "deleteFile",
                                      meth: HttpMethod.HttpPost,
                                      host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.DeleteFile",
                                      validator: validate_DeleteFile_603208,
                                      base: "/", url: url_DeleteFile_603209,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRepository_603222 = ref object of OpenApiRestCall_602466
proc url_DeleteRepository_603224(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRepository_603223(path: JsonNode; query: JsonNode;
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
  var valid_603225 = header.getOrDefault("X-Amz-Date")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Date", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603227 = header.getOrDefault("X-Amz-Target")
  valid_603227 = validateParameter(valid_603227, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteRepository"))
  if valid_603227 != nil:
    section.add "X-Amz-Target", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Content-Sha256", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Algorithm")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Algorithm", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Credential")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Credential", valid_603232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_DeleteRepository_603222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a repository. If a specified repository was already deleted, a null repository ID will be returned.</p> <important> <p>Deleting a repository also deletes all associated objects and metadata. After a repository is deleted, all future push calls to the deleted repository will fail.</p> </important>
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_DeleteRepository_603222; body: JsonNode): Recallable =
  ## deleteRepository
  ## <p>Deletes a repository. If a specified repository was already deleted, a null repository ID will be returned.</p> <important> <p>Deleting a repository also deletes all associated objects and metadata. After a repository is deleted, all future push calls to the deleted repository will fail.</p> </important>
  ##   body: JObject (required)
  var body_603236 = newJObject()
  if body != nil:
    body_603236 = body
  result = call_603235.call(nil, nil, nil, nil, body_603236)

var deleteRepository* = Call_DeleteRepository_603222(name: "deleteRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteRepository",
    validator: validate_DeleteRepository_603223, base: "/",
    url: url_DeleteRepository_603224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMergeConflicts_603237 = ref object of OpenApiRestCall_602466
proc url_DescribeMergeConflicts_603239(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeMergeConflicts_603238(path: JsonNode; query: JsonNode;
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
  var valid_603240 = query.getOrDefault("maxMergeHunks")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "maxMergeHunks", valid_603240
  var valid_603241 = query.getOrDefault("nextToken")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "nextToken", valid_603241
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
  var valid_603242 = header.getOrDefault("X-Amz-Date")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Date", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Security-Token")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Security-Token", valid_603243
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603244 = header.getOrDefault("X-Amz-Target")
  valid_603244 = validateParameter(valid_603244, JString, required = true, default = newJString(
      "CodeCommit_20150413.DescribeMergeConflicts"))
  if valid_603244 != nil:
    section.add "X-Amz-Target", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Content-Sha256", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Algorithm")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Algorithm", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Signature")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Signature", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-SignedHeaders", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Credential")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Credential", valid_603249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603251: Call_DescribeMergeConflicts_603237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy. If the merge option for the attempted merge is specified as FAST_FORWARD_MERGE, an exception will be thrown.
  ## 
  let valid = call_603251.validator(path, query, header, formData, body)
  let scheme = call_603251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603251.url(scheme.get, call_603251.host, call_603251.base,
                         call_603251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603251, url, valid)

proc call*(call_603252: Call_DescribeMergeConflicts_603237; body: JsonNode;
          maxMergeHunks: string = ""; nextToken: string = ""): Recallable =
  ## describeMergeConflicts
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy. If the merge option for the attempted merge is specified as FAST_FORWARD_MERGE, an exception will be thrown.
  ##   maxMergeHunks: string
  ##                : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603253 = newJObject()
  var body_603254 = newJObject()
  add(query_603253, "maxMergeHunks", newJString(maxMergeHunks))
  add(query_603253, "nextToken", newJString(nextToken))
  if body != nil:
    body_603254 = body
  result = call_603252.call(nil, query_603253, nil, nil, body_603254)

var describeMergeConflicts* = Call_DescribeMergeConflicts_603237(
    name: "describeMergeConflicts", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DescribeMergeConflicts",
    validator: validate_DescribeMergeConflicts_603238, base: "/",
    url: url_DescribeMergeConflicts_603239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePullRequestEvents_603256 = ref object of OpenApiRestCall_602466
proc url_DescribePullRequestEvents_603258(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePullRequestEvents_603257(path: JsonNode; query: JsonNode;
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
  var valid_603259 = query.getOrDefault("maxResults")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "maxResults", valid_603259
  var valid_603260 = query.getOrDefault("nextToken")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "nextToken", valid_603260
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
  var valid_603261 = header.getOrDefault("X-Amz-Date")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-Date", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Security-Token")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Security-Token", valid_603262
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603263 = header.getOrDefault("X-Amz-Target")
  valid_603263 = validateParameter(valid_603263, JString, required = true, default = newJString(
      "CodeCommit_20150413.DescribePullRequestEvents"))
  if valid_603263 != nil:
    section.add "X-Amz-Target", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Content-Sha256", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Algorithm")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Algorithm", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-Signature")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Signature", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-SignedHeaders", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Credential")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Credential", valid_603268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603270: Call_DescribePullRequestEvents_603256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about one or more pull request events.
  ## 
  let valid = call_603270.validator(path, query, header, formData, body)
  let scheme = call_603270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603270.url(scheme.get, call_603270.host, call_603270.base,
                         call_603270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603270, url, valid)

proc call*(call_603271: Call_DescribePullRequestEvents_603256; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## describePullRequestEvents
  ## Returns information about one or more pull request events.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603272 = newJObject()
  var body_603273 = newJObject()
  add(query_603272, "maxResults", newJString(maxResults))
  add(query_603272, "nextToken", newJString(nextToken))
  if body != nil:
    body_603273 = body
  result = call_603271.call(nil, query_603272, nil, nil, body_603273)

var describePullRequestEvents* = Call_DescribePullRequestEvents_603256(
    name: "describePullRequestEvents", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DescribePullRequestEvents",
    validator: validate_DescribePullRequestEvents_603257, base: "/",
    url: url_DescribePullRequestEvents_603258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlob_603274 = ref object of OpenApiRestCall_602466
proc url_GetBlob_603276(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBlob_603275(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603277 = header.getOrDefault("X-Amz-Date")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Date", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Security-Token")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Security-Token", valid_603278
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603279 = header.getOrDefault("X-Amz-Target")
  valid_603279 = validateParameter(valid_603279, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetBlob"))
  if valid_603279 != nil:
    section.add "X-Amz-Target", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Content-Sha256", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-Algorithm")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Algorithm", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Signature")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Signature", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-SignedHeaders", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Credential")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Credential", valid_603284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603286: Call_GetBlob_603274; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the base-64 encoded content of an individual blob within a repository.
  ## 
  let valid = call_603286.validator(path, query, header, formData, body)
  let scheme = call_603286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603286.url(scheme.get, call_603286.host, call_603286.base,
                         call_603286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603286, url, valid)

proc call*(call_603287: Call_GetBlob_603274; body: JsonNode): Recallable =
  ## getBlob
  ## Returns the base-64 encoded content of an individual blob within a repository.
  ##   body: JObject (required)
  var body_603288 = newJObject()
  if body != nil:
    body_603288 = body
  result = call_603287.call(nil, nil, nil, nil, body_603288)

var getBlob* = Call_GetBlob_603274(name: "getBlob", meth: HttpMethod.HttpPost,
                                host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetBlob",
                                validator: validate_GetBlob_603275, base: "/",
                                url: url_GetBlob_603276,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBranch_603289 = ref object of OpenApiRestCall_602466
proc url_GetBranch_603291(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBranch_603290(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603292 = header.getOrDefault("X-Amz-Date")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Date", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Security-Token")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Security-Token", valid_603293
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603294 = header.getOrDefault("X-Amz-Target")
  valid_603294 = validateParameter(valid_603294, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetBranch"))
  if valid_603294 != nil:
    section.add "X-Amz-Target", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Content-Sha256", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Algorithm")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Algorithm", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-Signature")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Signature", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-SignedHeaders", valid_603298
  var valid_603299 = header.getOrDefault("X-Amz-Credential")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-Credential", valid_603299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603301: Call_GetBranch_603289; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a repository branch, including its name and the last commit ID.
  ## 
  let valid = call_603301.validator(path, query, header, formData, body)
  let scheme = call_603301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603301.url(scheme.get, call_603301.host, call_603301.base,
                         call_603301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603301, url, valid)

proc call*(call_603302: Call_GetBranch_603289; body: JsonNode): Recallable =
  ## getBranch
  ## Returns information about a repository branch, including its name and the last commit ID.
  ##   body: JObject (required)
  var body_603303 = newJObject()
  if body != nil:
    body_603303 = body
  result = call_603302.call(nil, nil, nil, nil, body_603303)

var getBranch* = Call_GetBranch_603289(name: "getBranch", meth: HttpMethod.HttpPost,
                                    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetBranch",
                                    validator: validate_GetBranch_603290,
                                    base: "/", url: url_GetBranch_603291,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComment_603304 = ref object of OpenApiRestCall_602466
proc url_GetComment_603306(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetComment_603305(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603307 = header.getOrDefault("X-Amz-Date")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Date", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Security-Token")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Security-Token", valid_603308
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603309 = header.getOrDefault("X-Amz-Target")
  valid_603309 = validateParameter(valid_603309, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetComment"))
  if valid_603309 != nil:
    section.add "X-Amz-Target", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Content-Sha256", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-Algorithm")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-Algorithm", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Signature")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Signature", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-SignedHeaders", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-Credential")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Credential", valid_603314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603316: Call_GetComment_603304; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the content of a comment made on a change, file, or commit in a repository.
  ## 
  let valid = call_603316.validator(path, query, header, formData, body)
  let scheme = call_603316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603316.url(scheme.get, call_603316.host, call_603316.base,
                         call_603316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603316, url, valid)

proc call*(call_603317: Call_GetComment_603304; body: JsonNode): Recallable =
  ## getComment
  ## Returns the content of a comment made on a change, file, or commit in a repository.
  ##   body: JObject (required)
  var body_603318 = newJObject()
  if body != nil:
    body_603318 = body
  result = call_603317.call(nil, nil, nil, nil, body_603318)

var getComment* = Call_GetComment_603304(name: "getComment",
                                      meth: HttpMethod.HttpPost,
                                      host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetComment",
                                      validator: validate_GetComment_603305,
                                      base: "/", url: url_GetComment_603306,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommentsForComparedCommit_603319 = ref object of OpenApiRestCall_602466
proc url_GetCommentsForComparedCommit_603321(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCommentsForComparedCommit_603320(path: JsonNode; query: JsonNode;
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
  var valid_603322 = query.getOrDefault("maxResults")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "maxResults", valid_603322
  var valid_603323 = query.getOrDefault("nextToken")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "nextToken", valid_603323
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
  var valid_603324 = header.getOrDefault("X-Amz-Date")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Date", valid_603324
  var valid_603325 = header.getOrDefault("X-Amz-Security-Token")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-Security-Token", valid_603325
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603326 = header.getOrDefault("X-Amz-Target")
  valid_603326 = validateParameter(valid_603326, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommentsForComparedCommit"))
  if valid_603326 != nil:
    section.add "X-Amz-Target", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Content-Sha256", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Algorithm")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Algorithm", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Signature")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Signature", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-SignedHeaders", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Credential")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Credential", valid_603331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603333: Call_GetCommentsForComparedCommit_603319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about comments made on the comparison between two commits.
  ## 
  let valid = call_603333.validator(path, query, header, formData, body)
  let scheme = call_603333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603333.url(scheme.get, call_603333.host, call_603333.base,
                         call_603333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603333, url, valid)

proc call*(call_603334: Call_GetCommentsForComparedCommit_603319; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getCommentsForComparedCommit
  ## Returns information about comments made on the comparison between two commits.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603335 = newJObject()
  var body_603336 = newJObject()
  add(query_603335, "maxResults", newJString(maxResults))
  add(query_603335, "nextToken", newJString(nextToken))
  if body != nil:
    body_603336 = body
  result = call_603334.call(nil, query_603335, nil, nil, body_603336)

var getCommentsForComparedCommit* = Call_GetCommentsForComparedCommit_603319(
    name: "getCommentsForComparedCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetCommentsForComparedCommit",
    validator: validate_GetCommentsForComparedCommit_603320, base: "/",
    url: url_GetCommentsForComparedCommit_603321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommentsForPullRequest_603337 = ref object of OpenApiRestCall_602466
proc url_GetCommentsForPullRequest_603339(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCommentsForPullRequest_603338(path: JsonNode; query: JsonNode;
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
  var valid_603340 = query.getOrDefault("maxResults")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "maxResults", valid_603340
  var valid_603341 = query.getOrDefault("nextToken")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "nextToken", valid_603341
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
  var valid_603342 = header.getOrDefault("X-Amz-Date")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-Date", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-Security-Token")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Security-Token", valid_603343
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603344 = header.getOrDefault("X-Amz-Target")
  valid_603344 = validateParameter(valid_603344, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommentsForPullRequest"))
  if valid_603344 != nil:
    section.add "X-Amz-Target", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Content-Sha256", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Algorithm")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Algorithm", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-Signature")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Signature", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-SignedHeaders", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Credential")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Credential", valid_603349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603351: Call_GetCommentsForPullRequest_603337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns comments made on a pull request.
  ## 
  let valid = call_603351.validator(path, query, header, formData, body)
  let scheme = call_603351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603351.url(scheme.get, call_603351.host, call_603351.base,
                         call_603351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603351, url, valid)

proc call*(call_603352: Call_GetCommentsForPullRequest_603337; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## getCommentsForPullRequest
  ## Returns comments made on a pull request.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603353 = newJObject()
  var body_603354 = newJObject()
  add(query_603353, "maxResults", newJString(maxResults))
  add(query_603353, "nextToken", newJString(nextToken))
  if body != nil:
    body_603354 = body
  result = call_603352.call(nil, query_603353, nil, nil, body_603354)

var getCommentsForPullRequest* = Call_GetCommentsForPullRequest_603337(
    name: "getCommentsForPullRequest", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetCommentsForPullRequest",
    validator: validate_GetCommentsForPullRequest_603338, base: "/",
    url: url_GetCommentsForPullRequest_603339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommit_603355 = ref object of OpenApiRestCall_602466
proc url_GetCommit_603357(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCommit_603356(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603358 = header.getOrDefault("X-Amz-Date")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Date", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Security-Token")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Security-Token", valid_603359
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603360 = header.getOrDefault("X-Amz-Target")
  valid_603360 = validateParameter(valid_603360, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommit"))
  if valid_603360 != nil:
    section.add "X-Amz-Target", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Content-Sha256", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Algorithm")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Algorithm", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Signature")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Signature", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-SignedHeaders", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Credential")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Credential", valid_603365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603367: Call_GetCommit_603355; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a commit, including commit message and committer information.
  ## 
  let valid = call_603367.validator(path, query, header, formData, body)
  let scheme = call_603367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603367.url(scheme.get, call_603367.host, call_603367.base,
                         call_603367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603367, url, valid)

proc call*(call_603368: Call_GetCommit_603355; body: JsonNode): Recallable =
  ## getCommit
  ## Returns information about a commit, including commit message and committer information.
  ##   body: JObject (required)
  var body_603369 = newJObject()
  if body != nil:
    body_603369 = body
  result = call_603368.call(nil, nil, nil, nil, body_603369)

var getCommit* = Call_GetCommit_603355(name: "getCommit", meth: HttpMethod.HttpPost,
                                    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetCommit",
                                    validator: validate_GetCommit_603356,
                                    base: "/", url: url_GetCommit_603357,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDifferences_603370 = ref object of OpenApiRestCall_602466
proc url_GetDifferences_603372(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDifferences_603371(path: JsonNode; query: JsonNode;
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
  var valid_603373 = query.getOrDefault("NextToken")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "NextToken", valid_603373
  var valid_603374 = query.getOrDefault("MaxResults")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "MaxResults", valid_603374
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
  var valid_603375 = header.getOrDefault("X-Amz-Date")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Date", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Security-Token")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Security-Token", valid_603376
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603377 = header.getOrDefault("X-Amz-Target")
  valid_603377 = validateParameter(valid_603377, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetDifferences"))
  if valid_603377 != nil:
    section.add "X-Amz-Target", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Content-Sha256", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Algorithm")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Algorithm", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Signature")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Signature", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-SignedHeaders", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Credential")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Credential", valid_603382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603384: Call_GetDifferences_603370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID or other fully qualified reference). Results can be limited to a specified path.
  ## 
  let valid = call_603384.validator(path, query, header, formData, body)
  let scheme = call_603384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603384.url(scheme.get, call_603384.host, call_603384.base,
                         call_603384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603384, url, valid)

proc call*(call_603385: Call_GetDifferences_603370; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getDifferences
  ## Returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID or other fully qualified reference). Results can be limited to a specified path.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603386 = newJObject()
  var body_603387 = newJObject()
  add(query_603386, "NextToken", newJString(NextToken))
  if body != nil:
    body_603387 = body
  add(query_603386, "MaxResults", newJString(MaxResults))
  result = call_603385.call(nil, query_603386, nil, nil, body_603387)

var getDifferences* = Call_GetDifferences_603370(name: "getDifferences",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetDifferences",
    validator: validate_GetDifferences_603371, base: "/", url: url_GetDifferences_603372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFile_603388 = ref object of OpenApiRestCall_602466
proc url_GetFile_603390(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetFile_603389(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603391 = header.getOrDefault("X-Amz-Date")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Date", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Security-Token")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Security-Token", valid_603392
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603393 = header.getOrDefault("X-Amz-Target")
  valid_603393 = validateParameter(valid_603393, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetFile"))
  if valid_603393 != nil:
    section.add "X-Amz-Target", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Content-Sha256", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Algorithm")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Algorithm", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-Signature")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-Signature", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-SignedHeaders", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-Credential")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Credential", valid_603398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603400: Call_GetFile_603388; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the base-64 encoded contents of a specified file and its metadata.
  ## 
  let valid = call_603400.validator(path, query, header, formData, body)
  let scheme = call_603400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603400.url(scheme.get, call_603400.host, call_603400.base,
                         call_603400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603400, url, valid)

proc call*(call_603401: Call_GetFile_603388; body: JsonNode): Recallable =
  ## getFile
  ## Returns the base-64 encoded contents of a specified file and its metadata.
  ##   body: JObject (required)
  var body_603402 = newJObject()
  if body != nil:
    body_603402 = body
  result = call_603401.call(nil, nil, nil, nil, body_603402)

var getFile* = Call_GetFile_603388(name: "getFile", meth: HttpMethod.HttpPost,
                                host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetFile",
                                validator: validate_GetFile_603389, base: "/",
                                url: url_GetFile_603390,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolder_603403 = ref object of OpenApiRestCall_602466
proc url_GetFolder_603405(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetFolder_603404(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603406 = header.getOrDefault("X-Amz-Date")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Date", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Security-Token")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Security-Token", valid_603407
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603408 = header.getOrDefault("X-Amz-Target")
  valid_603408 = validateParameter(valid_603408, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetFolder"))
  if valid_603408 != nil:
    section.add "X-Amz-Target", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Content-Sha256", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Algorithm")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Algorithm", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-Signature")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Signature", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-SignedHeaders", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-Credential")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-Credential", valid_603413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603415: Call_GetFolder_603403; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the contents of a specified folder in a repository.
  ## 
  let valid = call_603415.validator(path, query, header, formData, body)
  let scheme = call_603415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603415.url(scheme.get, call_603415.host, call_603415.base,
                         call_603415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603415, url, valid)

proc call*(call_603416: Call_GetFolder_603403; body: JsonNode): Recallable =
  ## getFolder
  ## Returns the contents of a specified folder in a repository.
  ##   body: JObject (required)
  var body_603417 = newJObject()
  if body != nil:
    body_603417 = body
  result = call_603416.call(nil, nil, nil, nil, body_603417)

var getFolder* = Call_GetFolder_603403(name: "getFolder", meth: HttpMethod.HttpPost,
                                    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetFolder",
                                    validator: validate_GetFolder_603404,
                                    base: "/", url: url_GetFolder_603405,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeCommit_603418 = ref object of OpenApiRestCall_602466
proc url_GetMergeCommit_603420(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMergeCommit_603419(path: JsonNode; query: JsonNode;
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
  var valid_603421 = header.getOrDefault("X-Amz-Date")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Date", valid_603421
  var valid_603422 = header.getOrDefault("X-Amz-Security-Token")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Security-Token", valid_603422
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603423 = header.getOrDefault("X-Amz-Target")
  valid_603423 = validateParameter(valid_603423, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeCommit"))
  if valid_603423 != nil:
    section.add "X-Amz-Target", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Content-Sha256", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Algorithm")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Algorithm", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Signature")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Signature", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-SignedHeaders", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Credential")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Credential", valid_603428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603430: Call_GetMergeCommit_603418; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified merge commit.
  ## 
  let valid = call_603430.validator(path, query, header, formData, body)
  let scheme = call_603430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603430.url(scheme.get, call_603430.host, call_603430.base,
                         call_603430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603430, url, valid)

proc call*(call_603431: Call_GetMergeCommit_603418; body: JsonNode): Recallable =
  ## getMergeCommit
  ## Returns information about a specified merge commit.
  ##   body: JObject (required)
  var body_603432 = newJObject()
  if body != nil:
    body_603432 = body
  result = call_603431.call(nil, nil, nil, nil, body_603432)

var getMergeCommit* = Call_GetMergeCommit_603418(name: "getMergeCommit",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeCommit",
    validator: validate_GetMergeCommit_603419, base: "/", url: url_GetMergeCommit_603420,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeConflicts_603433 = ref object of OpenApiRestCall_602466
proc url_GetMergeConflicts_603435(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMergeConflicts_603434(path: JsonNode; query: JsonNode;
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
  var valid_603436 = query.getOrDefault("nextToken")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "nextToken", valid_603436
  var valid_603437 = query.getOrDefault("maxConflictFiles")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "maxConflictFiles", valid_603437
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
  var valid_603438 = header.getOrDefault("X-Amz-Date")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Date", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Security-Token")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Security-Token", valid_603439
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603440 = header.getOrDefault("X-Amz-Target")
  valid_603440 = validateParameter(valid_603440, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeConflicts"))
  if valid_603440 != nil:
    section.add "X-Amz-Target", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Content-Sha256", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Algorithm")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Algorithm", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Signature")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Signature", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-SignedHeaders", valid_603444
  var valid_603445 = header.getOrDefault("X-Amz-Credential")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-Credential", valid_603445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603447: Call_GetMergeConflicts_603433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about merge conflicts between the before and after commit IDs for a pull request in a repository.
  ## 
  let valid = call_603447.validator(path, query, header, formData, body)
  let scheme = call_603447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603447.url(scheme.get, call_603447.host, call_603447.base,
                         call_603447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603447, url, valid)

proc call*(call_603448: Call_GetMergeConflicts_603433; body: JsonNode;
          nextToken: string = ""; maxConflictFiles: string = ""): Recallable =
  ## getMergeConflicts
  ## Returns information about merge conflicts between the before and after commit IDs for a pull request in a repository.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxConflictFiles: string
  ##                   : Pagination limit
  var query_603449 = newJObject()
  var body_603450 = newJObject()
  add(query_603449, "nextToken", newJString(nextToken))
  if body != nil:
    body_603450 = body
  add(query_603449, "maxConflictFiles", newJString(maxConflictFiles))
  result = call_603448.call(nil, query_603449, nil, nil, body_603450)

var getMergeConflicts* = Call_GetMergeConflicts_603433(name: "getMergeConflicts",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeConflicts",
    validator: validate_GetMergeConflicts_603434, base: "/",
    url: url_GetMergeConflicts_603435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeOptions_603451 = ref object of OpenApiRestCall_602466
proc url_GetMergeOptions_603453(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetMergeOptions_603452(path: JsonNode; query: JsonNode;
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
  var valid_603454 = header.getOrDefault("X-Amz-Date")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Date", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Security-Token")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Security-Token", valid_603455
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603456 = header.getOrDefault("X-Amz-Target")
  valid_603456 = validateParameter(valid_603456, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeOptions"))
  if valid_603456 != nil:
    section.add "X-Amz-Target", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Content-Sha256", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Algorithm")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Algorithm", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Signature")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Signature", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-SignedHeaders", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Credential")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Credential", valid_603461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603463: Call_GetMergeOptions_603451; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the merge options available for merging two specified branches. For details about why a particular merge option is not available, use GetMergeConflicts or DescribeMergeConflicts.
  ## 
  let valid = call_603463.validator(path, query, header, formData, body)
  let scheme = call_603463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603463.url(scheme.get, call_603463.host, call_603463.base,
                         call_603463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603463, url, valid)

proc call*(call_603464: Call_GetMergeOptions_603451; body: JsonNode): Recallable =
  ## getMergeOptions
  ## Returns information about the merge options available for merging two specified branches. For details about why a particular merge option is not available, use GetMergeConflicts or DescribeMergeConflicts.
  ##   body: JObject (required)
  var body_603465 = newJObject()
  if body != nil:
    body_603465 = body
  result = call_603464.call(nil, nil, nil, nil, body_603465)

var getMergeOptions* = Call_GetMergeOptions_603451(name: "getMergeOptions",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeOptions",
    validator: validate_GetMergeOptions_603452, base: "/", url: url_GetMergeOptions_603453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPullRequest_603466 = ref object of OpenApiRestCall_602466
proc url_GetPullRequest_603468(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPullRequest_603467(path: JsonNode; query: JsonNode;
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
  var valid_603469 = header.getOrDefault("X-Amz-Date")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Date", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Security-Token")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Security-Token", valid_603470
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603471 = header.getOrDefault("X-Amz-Target")
  valid_603471 = validateParameter(valid_603471, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetPullRequest"))
  if valid_603471 != nil:
    section.add "X-Amz-Target", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Content-Sha256", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Algorithm")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Algorithm", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Signature")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Signature", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-SignedHeaders", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Credential")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Credential", valid_603476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603478: Call_GetPullRequest_603466; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a pull request in a specified repository.
  ## 
  let valid = call_603478.validator(path, query, header, formData, body)
  let scheme = call_603478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603478.url(scheme.get, call_603478.host, call_603478.base,
                         call_603478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603478, url, valid)

proc call*(call_603479: Call_GetPullRequest_603466; body: JsonNode): Recallable =
  ## getPullRequest
  ## Gets information about a pull request in a specified repository.
  ##   body: JObject (required)
  var body_603480 = newJObject()
  if body != nil:
    body_603480 = body
  result = call_603479.call(nil, nil, nil, nil, body_603480)

var getPullRequest* = Call_GetPullRequest_603466(name: "getPullRequest",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetPullRequest",
    validator: validate_GetPullRequest_603467, base: "/", url: url_GetPullRequest_603468,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepository_603481 = ref object of OpenApiRestCall_602466
proc url_GetRepository_603483(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRepository_603482(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603484 = header.getOrDefault("X-Amz-Date")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Date", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Security-Token")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Security-Token", valid_603485
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603486 = header.getOrDefault("X-Amz-Target")
  valid_603486 = validateParameter(valid_603486, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetRepository"))
  if valid_603486 != nil:
    section.add "X-Amz-Target", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Content-Sha256", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Algorithm")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Algorithm", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-Signature")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-Signature", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-SignedHeaders", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-Credential")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Credential", valid_603491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603493: Call_GetRepository_603481; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ## 
  let valid = call_603493.validator(path, query, header, formData, body)
  let scheme = call_603493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603493.url(scheme.get, call_603493.host, call_603493.base,
                         call_603493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603493, url, valid)

proc call*(call_603494: Call_GetRepository_603481; body: JsonNode): Recallable =
  ## getRepository
  ## <p>Returns information about a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ##   body: JObject (required)
  var body_603495 = newJObject()
  if body != nil:
    body_603495 = body
  result = call_603494.call(nil, nil, nil, nil, body_603495)

var getRepository* = Call_GetRepository_603481(name: "getRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetRepository",
    validator: validate_GetRepository_603482, base: "/", url: url_GetRepository_603483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepositoryTriggers_603496 = ref object of OpenApiRestCall_602466
proc url_GetRepositoryTriggers_603498(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRepositoryTriggers_603497(path: JsonNode; query: JsonNode;
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
  var valid_603499 = header.getOrDefault("X-Amz-Date")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Date", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Security-Token")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Security-Token", valid_603500
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603501 = header.getOrDefault("X-Amz-Target")
  valid_603501 = validateParameter(valid_603501, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetRepositoryTriggers"))
  if valid_603501 != nil:
    section.add "X-Amz-Target", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Content-Sha256", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Algorithm")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Algorithm", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-Signature")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-Signature", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-SignedHeaders", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-Credential")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Credential", valid_603506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603508: Call_GetRepositoryTriggers_603496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about triggers configured for a repository.
  ## 
  let valid = call_603508.validator(path, query, header, formData, body)
  let scheme = call_603508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603508.url(scheme.get, call_603508.host, call_603508.base,
                         call_603508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603508, url, valid)

proc call*(call_603509: Call_GetRepositoryTriggers_603496; body: JsonNode): Recallable =
  ## getRepositoryTriggers
  ## Gets information about triggers configured for a repository.
  ##   body: JObject (required)
  var body_603510 = newJObject()
  if body != nil:
    body_603510 = body
  result = call_603509.call(nil, nil, nil, nil, body_603510)

var getRepositoryTriggers* = Call_GetRepositoryTriggers_603496(
    name: "getRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetRepositoryTriggers",
    validator: validate_GetRepositoryTriggers_603497, base: "/",
    url: url_GetRepositoryTriggers_603498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBranches_603511 = ref object of OpenApiRestCall_602466
proc url_ListBranches_603513(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListBranches_603512(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603514 = query.getOrDefault("nextToken")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "nextToken", valid_603514
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
  var valid_603515 = header.getOrDefault("X-Amz-Date")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Date", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-Security-Token")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Security-Token", valid_603516
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603517 = header.getOrDefault("X-Amz-Target")
  valid_603517 = validateParameter(valid_603517, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListBranches"))
  if valid_603517 != nil:
    section.add "X-Amz-Target", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Content-Sha256", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-Algorithm")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-Algorithm", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Signature")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Signature", valid_603520
  var valid_603521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-SignedHeaders", valid_603521
  var valid_603522 = header.getOrDefault("X-Amz-Credential")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-Credential", valid_603522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603524: Call_ListBranches_603511; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more branches in a repository.
  ## 
  let valid = call_603524.validator(path, query, header, formData, body)
  let scheme = call_603524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603524.url(scheme.get, call_603524.host, call_603524.base,
                         call_603524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603524, url, valid)

proc call*(call_603525: Call_ListBranches_603511; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listBranches
  ## Gets information about one or more branches in a repository.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603526 = newJObject()
  var body_603527 = newJObject()
  add(query_603526, "nextToken", newJString(nextToken))
  if body != nil:
    body_603527 = body
  result = call_603525.call(nil, query_603526, nil, nil, body_603527)

var listBranches* = Call_ListBranches_603511(name: "listBranches",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListBranches",
    validator: validate_ListBranches_603512, base: "/", url: url_ListBranches_603513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPullRequests_603528 = ref object of OpenApiRestCall_602466
proc url_ListPullRequests_603530(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListPullRequests_603529(path: JsonNode; query: JsonNode;
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
  var valid_603531 = query.getOrDefault("maxResults")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "maxResults", valid_603531
  var valid_603532 = query.getOrDefault("nextToken")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "nextToken", valid_603532
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
  var valid_603533 = header.getOrDefault("X-Amz-Date")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Date", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-Security-Token")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-Security-Token", valid_603534
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603535 = header.getOrDefault("X-Amz-Target")
  valid_603535 = validateParameter(valid_603535, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListPullRequests"))
  if valid_603535 != nil:
    section.add "X-Amz-Target", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Content-Sha256", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-Algorithm")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Algorithm", valid_603537
  var valid_603538 = header.getOrDefault("X-Amz-Signature")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Signature", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-SignedHeaders", valid_603539
  var valid_603540 = header.getOrDefault("X-Amz-Credential")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-Credential", valid_603540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603542: Call_ListPullRequests_603528; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of pull requests for a specified repository. The return list can be refined by pull request status or pull request author ARN.
  ## 
  let valid = call_603542.validator(path, query, header, formData, body)
  let scheme = call_603542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603542.url(scheme.get, call_603542.host, call_603542.base,
                         call_603542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603542, url, valid)

proc call*(call_603543: Call_ListPullRequests_603528; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listPullRequests
  ## Returns a list of pull requests for a specified repository. The return list can be refined by pull request status or pull request author ARN.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603544 = newJObject()
  var body_603545 = newJObject()
  add(query_603544, "maxResults", newJString(maxResults))
  add(query_603544, "nextToken", newJString(nextToken))
  if body != nil:
    body_603545 = body
  result = call_603543.call(nil, query_603544, nil, nil, body_603545)

var listPullRequests* = Call_ListPullRequests_603528(name: "listPullRequests",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListPullRequests",
    validator: validate_ListPullRequests_603529, base: "/",
    url: url_ListPullRequests_603530, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRepositories_603546 = ref object of OpenApiRestCall_602466
proc url_ListRepositories_603548(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRepositories_603547(path: JsonNode; query: JsonNode;
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
  var valid_603549 = query.getOrDefault("nextToken")
  valid_603549 = validateParameter(valid_603549, JString, required = false,
                                 default = nil)
  if valid_603549 != nil:
    section.add "nextToken", valid_603549
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
  var valid_603550 = header.getOrDefault("X-Amz-Date")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Date", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Security-Token")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Security-Token", valid_603551
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603552 = header.getOrDefault("X-Amz-Target")
  valid_603552 = validateParameter(valid_603552, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListRepositories"))
  if valid_603552 != nil:
    section.add "X-Amz-Target", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Content-Sha256", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Algorithm")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Algorithm", valid_603554
  var valid_603555 = header.getOrDefault("X-Amz-Signature")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Signature", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-SignedHeaders", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-Credential")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Credential", valid_603557
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603559: Call_ListRepositories_603546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more repositories.
  ## 
  let valid = call_603559.validator(path, query, header, formData, body)
  let scheme = call_603559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603559.url(scheme.get, call_603559.host, call_603559.base,
                         call_603559.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603559, url, valid)

proc call*(call_603560: Call_ListRepositories_603546; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listRepositories
  ## Gets information about one or more repositories.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603561 = newJObject()
  var body_603562 = newJObject()
  add(query_603561, "nextToken", newJString(nextToken))
  if body != nil:
    body_603562 = body
  result = call_603560.call(nil, query_603561, nil, nil, body_603562)

var listRepositories* = Call_ListRepositories_603546(name: "listRepositories",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListRepositories",
    validator: validate_ListRepositories_603547, base: "/",
    url: url_ListRepositories_603548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603563 = ref object of OpenApiRestCall_602466
proc url_ListTagsForResource_603565(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_603564(path: JsonNode; query: JsonNode;
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
  var valid_603566 = header.getOrDefault("X-Amz-Date")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Date", valid_603566
  var valid_603567 = header.getOrDefault("X-Amz-Security-Token")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-Security-Token", valid_603567
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603568 = header.getOrDefault("X-Amz-Target")
  valid_603568 = validateParameter(valid_603568, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListTagsForResource"))
  if valid_603568 != nil:
    section.add "X-Amz-Target", valid_603568
  var valid_603569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Content-Sha256", valid_603569
  var valid_603570 = header.getOrDefault("X-Amz-Algorithm")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Algorithm", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Signature")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Signature", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-SignedHeaders", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Credential")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Credential", valid_603573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603575: Call_ListTagsForResource_603563; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ## 
  let valid = call_603575.validator(path, query, header, formData, body)
  let scheme = call_603575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603575.url(scheme.get, call_603575.host, call_603575.base,
                         call_603575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603575, url, valid)

proc call*(call_603576: Call_ListTagsForResource_603563; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ##   body: JObject (required)
  var body_603577 = newJObject()
  if body != nil:
    body_603577 = body
  result = call_603576.call(nil, nil, nil, nil, body_603577)

var listTagsForResource* = Call_ListTagsForResource_603563(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListTagsForResource",
    validator: validate_ListTagsForResource_603564, base: "/",
    url: url_ListTagsForResource_603565, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesByFastForward_603578 = ref object of OpenApiRestCall_602466
proc url_MergeBranchesByFastForward_603580(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_MergeBranchesByFastForward_603579(path: JsonNode; query: JsonNode;
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
  var valid_603581 = header.getOrDefault("X-Amz-Date")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-Date", valid_603581
  var valid_603582 = header.getOrDefault("X-Amz-Security-Token")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-Security-Token", valid_603582
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603583 = header.getOrDefault("X-Amz-Target")
  valid_603583 = validateParameter(valid_603583, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesByFastForward"))
  if valid_603583 != nil:
    section.add "X-Amz-Target", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Content-Sha256", valid_603584
  var valid_603585 = header.getOrDefault("X-Amz-Algorithm")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Algorithm", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Signature")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Signature", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-SignedHeaders", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Credential")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Credential", valid_603588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603590: Call_MergeBranchesByFastForward_603578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Merges two branches using the fast-forward merge strategy.
  ## 
  let valid = call_603590.validator(path, query, header, formData, body)
  let scheme = call_603590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603590.url(scheme.get, call_603590.host, call_603590.base,
                         call_603590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603590, url, valid)

proc call*(call_603591: Call_MergeBranchesByFastForward_603578; body: JsonNode): Recallable =
  ## mergeBranchesByFastForward
  ## Merges two branches using the fast-forward merge strategy.
  ##   body: JObject (required)
  var body_603592 = newJObject()
  if body != nil:
    body_603592 = body
  result = call_603591.call(nil, nil, nil, nil, body_603592)

var mergeBranchesByFastForward* = Call_MergeBranchesByFastForward_603578(
    name: "mergeBranchesByFastForward", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesByFastForward",
    validator: validate_MergeBranchesByFastForward_603579, base: "/",
    url: url_MergeBranchesByFastForward_603580,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesBySquash_603593 = ref object of OpenApiRestCall_602466
proc url_MergeBranchesBySquash_603595(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_MergeBranchesBySquash_603594(path: JsonNode; query: JsonNode;
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
  var valid_603596 = header.getOrDefault("X-Amz-Date")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-Date", valid_603596
  var valid_603597 = header.getOrDefault("X-Amz-Security-Token")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "X-Amz-Security-Token", valid_603597
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603598 = header.getOrDefault("X-Amz-Target")
  valid_603598 = validateParameter(valid_603598, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesBySquash"))
  if valid_603598 != nil:
    section.add "X-Amz-Target", valid_603598
  var valid_603599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Content-Sha256", valid_603599
  var valid_603600 = header.getOrDefault("X-Amz-Algorithm")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Algorithm", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Signature")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Signature", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-SignedHeaders", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Credential")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Credential", valid_603603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603605: Call_MergeBranchesBySquash_603593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Merges two branches using the squash merge strategy.
  ## 
  let valid = call_603605.validator(path, query, header, formData, body)
  let scheme = call_603605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603605.url(scheme.get, call_603605.host, call_603605.base,
                         call_603605.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603605, url, valid)

proc call*(call_603606: Call_MergeBranchesBySquash_603593; body: JsonNode): Recallable =
  ## mergeBranchesBySquash
  ## Merges two branches using the squash merge strategy.
  ##   body: JObject (required)
  var body_603607 = newJObject()
  if body != nil:
    body_603607 = body
  result = call_603606.call(nil, nil, nil, nil, body_603607)

var mergeBranchesBySquash* = Call_MergeBranchesBySquash_603593(
    name: "mergeBranchesBySquash", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesBySquash",
    validator: validate_MergeBranchesBySquash_603594, base: "/",
    url: url_MergeBranchesBySquash_603595, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesByThreeWay_603608 = ref object of OpenApiRestCall_602466
proc url_MergeBranchesByThreeWay_603610(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_MergeBranchesByThreeWay_603609(path: JsonNode; query: JsonNode;
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
  var valid_603611 = header.getOrDefault("X-Amz-Date")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-Date", valid_603611
  var valid_603612 = header.getOrDefault("X-Amz-Security-Token")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "X-Amz-Security-Token", valid_603612
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603613 = header.getOrDefault("X-Amz-Target")
  valid_603613 = validateParameter(valid_603613, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesByThreeWay"))
  if valid_603613 != nil:
    section.add "X-Amz-Target", valid_603613
  var valid_603614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603614 = validateParameter(valid_603614, JString, required = false,
                                 default = nil)
  if valid_603614 != nil:
    section.add "X-Amz-Content-Sha256", valid_603614
  var valid_603615 = header.getOrDefault("X-Amz-Algorithm")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "X-Amz-Algorithm", valid_603615
  var valid_603616 = header.getOrDefault("X-Amz-Signature")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Signature", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-SignedHeaders", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Credential")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Credential", valid_603618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603620: Call_MergeBranchesByThreeWay_603608; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Merges two specified branches using the three-way merge strategy.
  ## 
  let valid = call_603620.validator(path, query, header, formData, body)
  let scheme = call_603620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603620.url(scheme.get, call_603620.host, call_603620.base,
                         call_603620.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603620, url, valid)

proc call*(call_603621: Call_MergeBranchesByThreeWay_603608; body: JsonNode): Recallable =
  ## mergeBranchesByThreeWay
  ## Merges two specified branches using the three-way merge strategy.
  ##   body: JObject (required)
  var body_603622 = newJObject()
  if body != nil:
    body_603622 = body
  result = call_603621.call(nil, nil, nil, nil, body_603622)

var mergeBranchesByThreeWay* = Call_MergeBranchesByThreeWay_603608(
    name: "mergeBranchesByThreeWay", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesByThreeWay",
    validator: validate_MergeBranchesByThreeWay_603609, base: "/",
    url: url_MergeBranchesByThreeWay_603610, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestByFastForward_603623 = ref object of OpenApiRestCall_602466
proc url_MergePullRequestByFastForward_603625(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_MergePullRequestByFastForward_603624(path: JsonNode; query: JsonNode;
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
  var valid_603626 = header.getOrDefault("X-Amz-Date")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Date", valid_603626
  var valid_603627 = header.getOrDefault("X-Amz-Security-Token")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "X-Amz-Security-Token", valid_603627
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603628 = header.getOrDefault("X-Amz-Target")
  valid_603628 = validateParameter(valid_603628, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestByFastForward"))
  if valid_603628 != nil:
    section.add "X-Amz-Target", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-Content-Sha256", valid_603629
  var valid_603630 = header.getOrDefault("X-Amz-Algorithm")
  valid_603630 = validateParameter(valid_603630, JString, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "X-Amz-Algorithm", valid_603630
  var valid_603631 = header.getOrDefault("X-Amz-Signature")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Signature", valid_603631
  var valid_603632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-SignedHeaders", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Credential")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Credential", valid_603633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603635: Call_MergePullRequestByFastForward_603623; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the fast-forward merge strategy. If the merge is successful, it closes the pull request.
  ## 
  let valid = call_603635.validator(path, query, header, formData, body)
  let scheme = call_603635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603635.url(scheme.get, call_603635.host, call_603635.base,
                         call_603635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603635, url, valid)

proc call*(call_603636: Call_MergePullRequestByFastForward_603623; body: JsonNode): Recallable =
  ## mergePullRequestByFastForward
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the fast-forward merge strategy. If the merge is successful, it closes the pull request.
  ##   body: JObject (required)
  var body_603637 = newJObject()
  if body != nil:
    body_603637 = body
  result = call_603636.call(nil, nil, nil, nil, body_603637)

var mergePullRequestByFastForward* = Call_MergePullRequestByFastForward_603623(
    name: "mergePullRequestByFastForward", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestByFastForward",
    validator: validate_MergePullRequestByFastForward_603624, base: "/",
    url: url_MergePullRequestByFastForward_603625,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestBySquash_603638 = ref object of OpenApiRestCall_602466
proc url_MergePullRequestBySquash_603640(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_MergePullRequestBySquash_603639(path: JsonNode; query: JsonNode;
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
  var valid_603641 = header.getOrDefault("X-Amz-Date")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Date", valid_603641
  var valid_603642 = header.getOrDefault("X-Amz-Security-Token")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "X-Amz-Security-Token", valid_603642
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603643 = header.getOrDefault("X-Amz-Target")
  valid_603643 = validateParameter(valid_603643, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestBySquash"))
  if valid_603643 != nil:
    section.add "X-Amz-Target", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Content-Sha256", valid_603644
  var valid_603645 = header.getOrDefault("X-Amz-Algorithm")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-Algorithm", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-Signature")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Signature", valid_603646
  var valid_603647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603647 = validateParameter(valid_603647, JString, required = false,
                                 default = nil)
  if valid_603647 != nil:
    section.add "X-Amz-SignedHeaders", valid_603647
  var valid_603648 = header.getOrDefault("X-Amz-Credential")
  valid_603648 = validateParameter(valid_603648, JString, required = false,
                                 default = nil)
  if valid_603648 != nil:
    section.add "X-Amz-Credential", valid_603648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603650: Call_MergePullRequestBySquash_603638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the squash merge strategy. If the merge is successful, it closes the pull request.
  ## 
  let valid = call_603650.validator(path, query, header, formData, body)
  let scheme = call_603650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603650.url(scheme.get, call_603650.host, call_603650.base,
                         call_603650.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603650, url, valid)

proc call*(call_603651: Call_MergePullRequestBySquash_603638; body: JsonNode): Recallable =
  ## mergePullRequestBySquash
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the squash merge strategy. If the merge is successful, it closes the pull request.
  ##   body: JObject (required)
  var body_603652 = newJObject()
  if body != nil:
    body_603652 = body
  result = call_603651.call(nil, nil, nil, nil, body_603652)

var mergePullRequestBySquash* = Call_MergePullRequestBySquash_603638(
    name: "mergePullRequestBySquash", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestBySquash",
    validator: validate_MergePullRequestBySquash_603639, base: "/",
    url: url_MergePullRequestBySquash_603640, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestByThreeWay_603653 = ref object of OpenApiRestCall_602466
proc url_MergePullRequestByThreeWay_603655(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_MergePullRequestByThreeWay_603654(path: JsonNode; query: JsonNode;
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
  var valid_603656 = header.getOrDefault("X-Amz-Date")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Date", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-Security-Token")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Security-Token", valid_603657
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603658 = header.getOrDefault("X-Amz-Target")
  valid_603658 = validateParameter(valid_603658, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestByThreeWay"))
  if valid_603658 != nil:
    section.add "X-Amz-Target", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Content-Sha256", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-Algorithm")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Algorithm", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-Signature")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Signature", valid_603661
  var valid_603662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "X-Amz-SignedHeaders", valid_603662
  var valid_603663 = header.getOrDefault("X-Amz-Credential")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-Credential", valid_603663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603665: Call_MergePullRequestByThreeWay_603653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the three-way merge strategy. If the merge is successful, it closes the pull request.
  ## 
  let valid = call_603665.validator(path, query, header, formData, body)
  let scheme = call_603665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603665.url(scheme.get, call_603665.host, call_603665.base,
                         call_603665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603665, url, valid)

proc call*(call_603666: Call_MergePullRequestByThreeWay_603653; body: JsonNode): Recallable =
  ## mergePullRequestByThreeWay
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the three-way merge strategy. If the merge is successful, it closes the pull request.
  ##   body: JObject (required)
  var body_603667 = newJObject()
  if body != nil:
    body_603667 = body
  result = call_603666.call(nil, nil, nil, nil, body_603667)

var mergePullRequestByThreeWay* = Call_MergePullRequestByThreeWay_603653(
    name: "mergePullRequestByThreeWay", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestByThreeWay",
    validator: validate_MergePullRequestByThreeWay_603654, base: "/",
    url: url_MergePullRequestByThreeWay_603655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentForComparedCommit_603668 = ref object of OpenApiRestCall_602466
proc url_PostCommentForComparedCommit_603670(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCommentForComparedCommit_603669(path: JsonNode; query: JsonNode;
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
  var valid_603671 = header.getOrDefault("X-Amz-Date")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Date", valid_603671
  var valid_603672 = header.getOrDefault("X-Amz-Security-Token")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Security-Token", valid_603672
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603673 = header.getOrDefault("X-Amz-Target")
  valid_603673 = validateParameter(valid_603673, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentForComparedCommit"))
  if valid_603673 != nil:
    section.add "X-Amz-Target", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Content-Sha256", valid_603674
  var valid_603675 = header.getOrDefault("X-Amz-Algorithm")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-Algorithm", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-Signature")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Signature", valid_603676
  var valid_603677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603677 = validateParameter(valid_603677, JString, required = false,
                                 default = nil)
  if valid_603677 != nil:
    section.add "X-Amz-SignedHeaders", valid_603677
  var valid_603678 = header.getOrDefault("X-Amz-Credential")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "X-Amz-Credential", valid_603678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603680: Call_PostCommentForComparedCommit_603668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Posts a comment on the comparison between two commits.
  ## 
  let valid = call_603680.validator(path, query, header, formData, body)
  let scheme = call_603680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603680.url(scheme.get, call_603680.host, call_603680.base,
                         call_603680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603680, url, valid)

proc call*(call_603681: Call_PostCommentForComparedCommit_603668; body: JsonNode): Recallable =
  ## postCommentForComparedCommit
  ## Posts a comment on the comparison between two commits.
  ##   body: JObject (required)
  var body_603682 = newJObject()
  if body != nil:
    body_603682 = body
  result = call_603681.call(nil, nil, nil, nil, body_603682)

var postCommentForComparedCommit* = Call_PostCommentForComparedCommit_603668(
    name: "postCommentForComparedCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentForComparedCommit",
    validator: validate_PostCommentForComparedCommit_603669, base: "/",
    url: url_PostCommentForComparedCommit_603670,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentForPullRequest_603683 = ref object of OpenApiRestCall_602466
proc url_PostCommentForPullRequest_603685(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCommentForPullRequest_603684(path: JsonNode; query: JsonNode;
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
  var valid_603686 = header.getOrDefault("X-Amz-Date")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-Date", valid_603686
  var valid_603687 = header.getOrDefault("X-Amz-Security-Token")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-Security-Token", valid_603687
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603688 = header.getOrDefault("X-Amz-Target")
  valid_603688 = validateParameter(valid_603688, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentForPullRequest"))
  if valid_603688 != nil:
    section.add "X-Amz-Target", valid_603688
  var valid_603689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-Content-Sha256", valid_603689
  var valid_603690 = header.getOrDefault("X-Amz-Algorithm")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Algorithm", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-Signature")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Signature", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-SignedHeaders", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-Credential")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-Credential", valid_603693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603695: Call_PostCommentForPullRequest_603683; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Posts a comment on a pull request.
  ## 
  let valid = call_603695.validator(path, query, header, formData, body)
  let scheme = call_603695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603695.url(scheme.get, call_603695.host, call_603695.base,
                         call_603695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603695, url, valid)

proc call*(call_603696: Call_PostCommentForPullRequest_603683; body: JsonNode): Recallable =
  ## postCommentForPullRequest
  ## Posts a comment on a pull request.
  ##   body: JObject (required)
  var body_603697 = newJObject()
  if body != nil:
    body_603697 = body
  result = call_603696.call(nil, nil, nil, nil, body_603697)

var postCommentForPullRequest* = Call_PostCommentForPullRequest_603683(
    name: "postCommentForPullRequest", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentForPullRequest",
    validator: validate_PostCommentForPullRequest_603684, base: "/",
    url: url_PostCommentForPullRequest_603685,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentReply_603698 = ref object of OpenApiRestCall_602466
proc url_PostCommentReply_603700(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCommentReply_603699(path: JsonNode; query: JsonNode;
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
  var valid_603701 = header.getOrDefault("X-Amz-Date")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-Date", valid_603701
  var valid_603702 = header.getOrDefault("X-Amz-Security-Token")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "X-Amz-Security-Token", valid_603702
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603703 = header.getOrDefault("X-Amz-Target")
  valid_603703 = validateParameter(valid_603703, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentReply"))
  if valid_603703 != nil:
    section.add "X-Amz-Target", valid_603703
  var valid_603704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "X-Amz-Content-Sha256", valid_603704
  var valid_603705 = header.getOrDefault("X-Amz-Algorithm")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-Algorithm", valid_603705
  var valid_603706 = header.getOrDefault("X-Amz-Signature")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-Signature", valid_603706
  var valid_603707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603707 = validateParameter(valid_603707, JString, required = false,
                                 default = nil)
  if valid_603707 != nil:
    section.add "X-Amz-SignedHeaders", valid_603707
  var valid_603708 = header.getOrDefault("X-Amz-Credential")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "X-Amz-Credential", valid_603708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603710: Call_PostCommentReply_603698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Posts a comment in reply to an existing comment on a comparison between commits or a pull request.
  ## 
  let valid = call_603710.validator(path, query, header, formData, body)
  let scheme = call_603710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603710.url(scheme.get, call_603710.host, call_603710.base,
                         call_603710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603710, url, valid)

proc call*(call_603711: Call_PostCommentReply_603698; body: JsonNode): Recallable =
  ## postCommentReply
  ## Posts a comment in reply to an existing comment on a comparison between commits or a pull request.
  ##   body: JObject (required)
  var body_603712 = newJObject()
  if body != nil:
    body_603712 = body
  result = call_603711.call(nil, nil, nil, nil, body_603712)

var postCommentReply* = Call_PostCommentReply_603698(name: "postCommentReply",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentReply",
    validator: validate_PostCommentReply_603699, base: "/",
    url: url_PostCommentReply_603700, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFile_603713 = ref object of OpenApiRestCall_602466
proc url_PutFile_603715(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutFile_603714(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603716 = header.getOrDefault("X-Amz-Date")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-Date", valid_603716
  var valid_603717 = header.getOrDefault("X-Amz-Security-Token")
  valid_603717 = validateParameter(valid_603717, JString, required = false,
                                 default = nil)
  if valid_603717 != nil:
    section.add "X-Amz-Security-Token", valid_603717
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603718 = header.getOrDefault("X-Amz-Target")
  valid_603718 = validateParameter(valid_603718, JString, required = true, default = newJString(
      "CodeCommit_20150413.PutFile"))
  if valid_603718 != nil:
    section.add "X-Amz-Target", valid_603718
  var valid_603719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Content-Sha256", valid_603719
  var valid_603720 = header.getOrDefault("X-Amz-Algorithm")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-Algorithm", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-Signature")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-Signature", valid_603721
  var valid_603722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-SignedHeaders", valid_603722
  var valid_603723 = header.getOrDefault("X-Amz-Credential")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "X-Amz-Credential", valid_603723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603725: Call_PutFile_603713; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates a file in a branch in an AWS CodeCommit repository, and generates a commit for the addition in the specified branch.
  ## 
  let valid = call_603725.validator(path, query, header, formData, body)
  let scheme = call_603725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603725.url(scheme.get, call_603725.host, call_603725.base,
                         call_603725.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603725, url, valid)

proc call*(call_603726: Call_PutFile_603713; body: JsonNode): Recallable =
  ## putFile
  ## Adds or updates a file in a branch in an AWS CodeCommit repository, and generates a commit for the addition in the specified branch.
  ##   body: JObject (required)
  var body_603727 = newJObject()
  if body != nil:
    body_603727 = body
  result = call_603726.call(nil, nil, nil, nil, body_603727)

var putFile* = Call_PutFile_603713(name: "putFile", meth: HttpMethod.HttpPost,
                                host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.PutFile",
                                validator: validate_PutFile_603714, base: "/",
                                url: url_PutFile_603715,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRepositoryTriggers_603728 = ref object of OpenApiRestCall_602466
proc url_PutRepositoryTriggers_603730(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutRepositoryTriggers_603729(path: JsonNode; query: JsonNode;
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
  var valid_603731 = header.getOrDefault("X-Amz-Date")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Date", valid_603731
  var valid_603732 = header.getOrDefault("X-Amz-Security-Token")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Security-Token", valid_603732
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603733 = header.getOrDefault("X-Amz-Target")
  valid_603733 = validateParameter(valid_603733, JString, required = true, default = newJString(
      "CodeCommit_20150413.PutRepositoryTriggers"))
  if valid_603733 != nil:
    section.add "X-Amz-Target", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Content-Sha256", valid_603734
  var valid_603735 = header.getOrDefault("X-Amz-Algorithm")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-Algorithm", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-Signature")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-Signature", valid_603736
  var valid_603737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "X-Amz-SignedHeaders", valid_603737
  var valid_603738 = header.getOrDefault("X-Amz-Credential")
  valid_603738 = validateParameter(valid_603738, JString, required = false,
                                 default = nil)
  if valid_603738 != nil:
    section.add "X-Amz-Credential", valid_603738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603740: Call_PutRepositoryTriggers_603728; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces all triggers for a repository. This can be used to create or delete triggers.
  ## 
  let valid = call_603740.validator(path, query, header, formData, body)
  let scheme = call_603740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603740.url(scheme.get, call_603740.host, call_603740.base,
                         call_603740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603740, url, valid)

proc call*(call_603741: Call_PutRepositoryTriggers_603728; body: JsonNode): Recallable =
  ## putRepositoryTriggers
  ## Replaces all triggers for a repository. This can be used to create or delete triggers.
  ##   body: JObject (required)
  var body_603742 = newJObject()
  if body != nil:
    body_603742 = body
  result = call_603741.call(nil, nil, nil, nil, body_603742)

var putRepositoryTriggers* = Call_PutRepositoryTriggers_603728(
    name: "putRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PutRepositoryTriggers",
    validator: validate_PutRepositoryTriggers_603729, base: "/",
    url: url_PutRepositoryTriggers_603730, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603743 = ref object of OpenApiRestCall_602466
proc url_TagResource_603745(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_603744(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603746 = header.getOrDefault("X-Amz-Date")
  valid_603746 = validateParameter(valid_603746, JString, required = false,
                                 default = nil)
  if valid_603746 != nil:
    section.add "X-Amz-Date", valid_603746
  var valid_603747 = header.getOrDefault("X-Amz-Security-Token")
  valid_603747 = validateParameter(valid_603747, JString, required = false,
                                 default = nil)
  if valid_603747 != nil:
    section.add "X-Amz-Security-Token", valid_603747
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603748 = header.getOrDefault("X-Amz-Target")
  valid_603748 = validateParameter(valid_603748, JString, required = true, default = newJString(
      "CodeCommit_20150413.TagResource"))
  if valid_603748 != nil:
    section.add "X-Amz-Target", valid_603748
  var valid_603749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-Content-Sha256", valid_603749
  var valid_603750 = header.getOrDefault("X-Amz-Algorithm")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-Algorithm", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-Signature")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Signature", valid_603751
  var valid_603752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-SignedHeaders", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-Credential")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-Credential", valid_603753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603755: Call_TagResource_603743; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ## 
  let valid = call_603755.validator(path, query, header, formData, body)
  let scheme = call_603755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603755.url(scheme.get, call_603755.host, call_603755.base,
                         call_603755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603755, url, valid)

proc call*(call_603756: Call_TagResource_603743; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ##   body: JObject (required)
  var body_603757 = newJObject()
  if body != nil:
    body_603757 = body
  result = call_603756.call(nil, nil, nil, nil, body_603757)

var tagResource* = Call_TagResource_603743(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.TagResource",
                                        validator: validate_TagResource_603744,
                                        base: "/", url: url_TagResource_603745,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestRepositoryTriggers_603758 = ref object of OpenApiRestCall_602466
proc url_TestRepositoryTriggers_603760(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TestRepositoryTriggers_603759(path: JsonNode; query: JsonNode;
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
  var valid_603761 = header.getOrDefault("X-Amz-Date")
  valid_603761 = validateParameter(valid_603761, JString, required = false,
                                 default = nil)
  if valid_603761 != nil:
    section.add "X-Amz-Date", valid_603761
  var valid_603762 = header.getOrDefault("X-Amz-Security-Token")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "X-Amz-Security-Token", valid_603762
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603763 = header.getOrDefault("X-Amz-Target")
  valid_603763 = validateParameter(valid_603763, JString, required = true, default = newJString(
      "CodeCommit_20150413.TestRepositoryTriggers"))
  if valid_603763 != nil:
    section.add "X-Amz-Target", valid_603763
  var valid_603764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-Content-Sha256", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Algorithm")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Algorithm", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-Signature")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Signature", valid_603766
  var valid_603767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-SignedHeaders", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-Credential")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-Credential", valid_603768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603770: Call_TestRepositoryTriggers_603758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tests the functionality of repository triggers by sending information to the trigger target. If real data is available in the repository, the test will send data from the last commit. If no data is available, sample data will be generated.
  ## 
  let valid = call_603770.validator(path, query, header, formData, body)
  let scheme = call_603770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603770.url(scheme.get, call_603770.host, call_603770.base,
                         call_603770.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603770, url, valid)

proc call*(call_603771: Call_TestRepositoryTriggers_603758; body: JsonNode): Recallable =
  ## testRepositoryTriggers
  ## Tests the functionality of repository triggers by sending information to the trigger target. If real data is available in the repository, the test will send data from the last commit. If no data is available, sample data will be generated.
  ##   body: JObject (required)
  var body_603772 = newJObject()
  if body != nil:
    body_603772 = body
  result = call_603771.call(nil, nil, nil, nil, body_603772)

var testRepositoryTriggers* = Call_TestRepositoryTriggers_603758(
    name: "testRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.TestRepositoryTriggers",
    validator: validate_TestRepositoryTriggers_603759, base: "/",
    url: url_TestRepositoryTriggers_603760, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603773 = ref object of OpenApiRestCall_602466
proc url_UntagResource_603775(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_603774(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603776 = header.getOrDefault("X-Amz-Date")
  valid_603776 = validateParameter(valid_603776, JString, required = false,
                                 default = nil)
  if valid_603776 != nil:
    section.add "X-Amz-Date", valid_603776
  var valid_603777 = header.getOrDefault("X-Amz-Security-Token")
  valid_603777 = validateParameter(valid_603777, JString, required = false,
                                 default = nil)
  if valid_603777 != nil:
    section.add "X-Amz-Security-Token", valid_603777
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603778 = header.getOrDefault("X-Amz-Target")
  valid_603778 = validateParameter(valid_603778, JString, required = true, default = newJString(
      "CodeCommit_20150413.UntagResource"))
  if valid_603778 != nil:
    section.add "X-Amz-Target", valid_603778
  var valid_603779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "X-Amz-Content-Sha256", valid_603779
  var valid_603780 = header.getOrDefault("X-Amz-Algorithm")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Algorithm", valid_603780
  var valid_603781 = header.getOrDefault("X-Amz-Signature")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "X-Amz-Signature", valid_603781
  var valid_603782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603782 = validateParameter(valid_603782, JString, required = false,
                                 default = nil)
  if valid_603782 != nil:
    section.add "X-Amz-SignedHeaders", valid_603782
  var valid_603783 = header.getOrDefault("X-Amz-Credential")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-Credential", valid_603783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603785: Call_UntagResource_603773; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ## 
  let valid = call_603785.validator(path, query, header, formData, body)
  let scheme = call_603785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603785.url(scheme.get, call_603785.host, call_603785.base,
                         call_603785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603785, url, valid)

proc call*(call_603786: Call_UntagResource_603773; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the AWS CodeCommit User Guide.
  ##   body: JObject (required)
  var body_603787 = newJObject()
  if body != nil:
    body_603787 = body
  result = call_603786.call(nil, nil, nil, nil, body_603787)

var untagResource* = Call_UntagResource_603773(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UntagResource",
    validator: validate_UntagResource_603774, base: "/", url: url_UntagResource_603775,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateComment_603788 = ref object of OpenApiRestCall_602466
proc url_UpdateComment_603790(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateComment_603789(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603791 = header.getOrDefault("X-Amz-Date")
  valid_603791 = validateParameter(valid_603791, JString, required = false,
                                 default = nil)
  if valid_603791 != nil:
    section.add "X-Amz-Date", valid_603791
  var valid_603792 = header.getOrDefault("X-Amz-Security-Token")
  valid_603792 = validateParameter(valid_603792, JString, required = false,
                                 default = nil)
  if valid_603792 != nil:
    section.add "X-Amz-Security-Token", valid_603792
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603793 = header.getOrDefault("X-Amz-Target")
  valid_603793 = validateParameter(valid_603793, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateComment"))
  if valid_603793 != nil:
    section.add "X-Amz-Target", valid_603793
  var valid_603794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603794 = validateParameter(valid_603794, JString, required = false,
                                 default = nil)
  if valid_603794 != nil:
    section.add "X-Amz-Content-Sha256", valid_603794
  var valid_603795 = header.getOrDefault("X-Amz-Algorithm")
  valid_603795 = validateParameter(valid_603795, JString, required = false,
                                 default = nil)
  if valid_603795 != nil:
    section.add "X-Amz-Algorithm", valid_603795
  var valid_603796 = header.getOrDefault("X-Amz-Signature")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "X-Amz-Signature", valid_603796
  var valid_603797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "X-Amz-SignedHeaders", valid_603797
  var valid_603798 = header.getOrDefault("X-Amz-Credential")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-Credential", valid_603798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603800: Call_UpdateComment_603788; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the contents of a comment.
  ## 
  let valid = call_603800.validator(path, query, header, formData, body)
  let scheme = call_603800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603800.url(scheme.get, call_603800.host, call_603800.base,
                         call_603800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603800, url, valid)

proc call*(call_603801: Call_UpdateComment_603788; body: JsonNode): Recallable =
  ## updateComment
  ## Replaces the contents of a comment.
  ##   body: JObject (required)
  var body_603802 = newJObject()
  if body != nil:
    body_603802 = body
  result = call_603801.call(nil, nil, nil, nil, body_603802)

var updateComment* = Call_UpdateComment_603788(name: "updateComment",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateComment",
    validator: validate_UpdateComment_603789, base: "/", url: url_UpdateComment_603790,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDefaultBranch_603803 = ref object of OpenApiRestCall_602466
proc url_UpdateDefaultBranch_603805(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateDefaultBranch_603804(path: JsonNode; query: JsonNode;
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
  var valid_603806 = header.getOrDefault("X-Amz-Date")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "X-Amz-Date", valid_603806
  var valid_603807 = header.getOrDefault("X-Amz-Security-Token")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = nil)
  if valid_603807 != nil:
    section.add "X-Amz-Security-Token", valid_603807
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603808 = header.getOrDefault("X-Amz-Target")
  valid_603808 = validateParameter(valid_603808, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateDefaultBranch"))
  if valid_603808 != nil:
    section.add "X-Amz-Target", valid_603808
  var valid_603809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603809 = validateParameter(valid_603809, JString, required = false,
                                 default = nil)
  if valid_603809 != nil:
    section.add "X-Amz-Content-Sha256", valid_603809
  var valid_603810 = header.getOrDefault("X-Amz-Algorithm")
  valid_603810 = validateParameter(valid_603810, JString, required = false,
                                 default = nil)
  if valid_603810 != nil:
    section.add "X-Amz-Algorithm", valid_603810
  var valid_603811 = header.getOrDefault("X-Amz-Signature")
  valid_603811 = validateParameter(valid_603811, JString, required = false,
                                 default = nil)
  if valid_603811 != nil:
    section.add "X-Amz-Signature", valid_603811
  var valid_603812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603812 = validateParameter(valid_603812, JString, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "X-Amz-SignedHeaders", valid_603812
  var valid_603813 = header.getOrDefault("X-Amz-Credential")
  valid_603813 = validateParameter(valid_603813, JString, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "X-Amz-Credential", valid_603813
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603815: Call_UpdateDefaultBranch_603803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or changes the default branch name for the specified repository.</p> <note> <p>If you use this operation to change the default branch name to the current default branch name, a success message is returned even though the default branch did not change.</p> </note>
  ## 
  let valid = call_603815.validator(path, query, header, formData, body)
  let scheme = call_603815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603815.url(scheme.get, call_603815.host, call_603815.base,
                         call_603815.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603815, url, valid)

proc call*(call_603816: Call_UpdateDefaultBranch_603803; body: JsonNode): Recallable =
  ## updateDefaultBranch
  ## <p>Sets or changes the default branch name for the specified repository.</p> <note> <p>If you use this operation to change the default branch name to the current default branch name, a success message is returned even though the default branch did not change.</p> </note>
  ##   body: JObject (required)
  var body_603817 = newJObject()
  if body != nil:
    body_603817 = body
  result = call_603816.call(nil, nil, nil, nil, body_603817)

var updateDefaultBranch* = Call_UpdateDefaultBranch_603803(
    name: "updateDefaultBranch", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateDefaultBranch",
    validator: validate_UpdateDefaultBranch_603804, base: "/",
    url: url_UpdateDefaultBranch_603805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestDescription_603818 = ref object of OpenApiRestCall_602466
proc url_UpdatePullRequestDescription_603820(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdatePullRequestDescription_603819(path: JsonNode; query: JsonNode;
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
  var valid_603821 = header.getOrDefault("X-Amz-Date")
  valid_603821 = validateParameter(valid_603821, JString, required = false,
                                 default = nil)
  if valid_603821 != nil:
    section.add "X-Amz-Date", valid_603821
  var valid_603822 = header.getOrDefault("X-Amz-Security-Token")
  valid_603822 = validateParameter(valid_603822, JString, required = false,
                                 default = nil)
  if valid_603822 != nil:
    section.add "X-Amz-Security-Token", valid_603822
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603823 = header.getOrDefault("X-Amz-Target")
  valid_603823 = validateParameter(valid_603823, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestDescription"))
  if valid_603823 != nil:
    section.add "X-Amz-Target", valid_603823
  var valid_603824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-Content-Sha256", valid_603824
  var valid_603825 = header.getOrDefault("X-Amz-Algorithm")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "X-Amz-Algorithm", valid_603825
  var valid_603826 = header.getOrDefault("X-Amz-Signature")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-Signature", valid_603826
  var valid_603827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "X-Amz-SignedHeaders", valid_603827
  var valid_603828 = header.getOrDefault("X-Amz-Credential")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "X-Amz-Credential", valid_603828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603830: Call_UpdatePullRequestDescription_603818; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the contents of the description of a pull request.
  ## 
  let valid = call_603830.validator(path, query, header, formData, body)
  let scheme = call_603830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603830.url(scheme.get, call_603830.host, call_603830.base,
                         call_603830.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603830, url, valid)

proc call*(call_603831: Call_UpdatePullRequestDescription_603818; body: JsonNode): Recallable =
  ## updatePullRequestDescription
  ## Replaces the contents of the description of a pull request.
  ##   body: JObject (required)
  var body_603832 = newJObject()
  if body != nil:
    body_603832 = body
  result = call_603831.call(nil, nil, nil, nil, body_603832)

var updatePullRequestDescription* = Call_UpdatePullRequestDescription_603818(
    name: "updatePullRequestDescription", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestDescription",
    validator: validate_UpdatePullRequestDescription_603819, base: "/",
    url: url_UpdatePullRequestDescription_603820,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestStatus_603833 = ref object of OpenApiRestCall_602466
proc url_UpdatePullRequestStatus_603835(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdatePullRequestStatus_603834(path: JsonNode; query: JsonNode;
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
  var valid_603836 = header.getOrDefault("X-Amz-Date")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Date", valid_603836
  var valid_603837 = header.getOrDefault("X-Amz-Security-Token")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "X-Amz-Security-Token", valid_603837
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603838 = header.getOrDefault("X-Amz-Target")
  valid_603838 = validateParameter(valid_603838, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestStatus"))
  if valid_603838 != nil:
    section.add "X-Amz-Target", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Content-Sha256", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-Algorithm")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-Algorithm", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-Signature")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Signature", valid_603841
  var valid_603842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "X-Amz-SignedHeaders", valid_603842
  var valid_603843 = header.getOrDefault("X-Amz-Credential")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "X-Amz-Credential", valid_603843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603845: Call_UpdatePullRequestStatus_603833; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of a pull request. 
  ## 
  let valid = call_603845.validator(path, query, header, formData, body)
  let scheme = call_603845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603845.url(scheme.get, call_603845.host, call_603845.base,
                         call_603845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603845, url, valid)

proc call*(call_603846: Call_UpdatePullRequestStatus_603833; body: JsonNode): Recallable =
  ## updatePullRequestStatus
  ## Updates the status of a pull request. 
  ##   body: JObject (required)
  var body_603847 = newJObject()
  if body != nil:
    body_603847 = body
  result = call_603846.call(nil, nil, nil, nil, body_603847)

var updatePullRequestStatus* = Call_UpdatePullRequestStatus_603833(
    name: "updatePullRequestStatus", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestStatus",
    validator: validate_UpdatePullRequestStatus_603834, base: "/",
    url: url_UpdatePullRequestStatus_603835, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestTitle_603848 = ref object of OpenApiRestCall_602466
proc url_UpdatePullRequestTitle_603850(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdatePullRequestTitle_603849(path: JsonNode; query: JsonNode;
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
  var valid_603851 = header.getOrDefault("X-Amz-Date")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "X-Amz-Date", valid_603851
  var valid_603852 = header.getOrDefault("X-Amz-Security-Token")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "X-Amz-Security-Token", valid_603852
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603853 = header.getOrDefault("X-Amz-Target")
  valid_603853 = validateParameter(valid_603853, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestTitle"))
  if valid_603853 != nil:
    section.add "X-Amz-Target", valid_603853
  var valid_603854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "X-Amz-Content-Sha256", valid_603854
  var valid_603855 = header.getOrDefault("X-Amz-Algorithm")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-Algorithm", valid_603855
  var valid_603856 = header.getOrDefault("X-Amz-Signature")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "X-Amz-Signature", valid_603856
  var valid_603857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "X-Amz-SignedHeaders", valid_603857
  var valid_603858 = header.getOrDefault("X-Amz-Credential")
  valid_603858 = validateParameter(valid_603858, JString, required = false,
                                 default = nil)
  if valid_603858 != nil:
    section.add "X-Amz-Credential", valid_603858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603860: Call_UpdatePullRequestTitle_603848; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the title of a pull request.
  ## 
  let valid = call_603860.validator(path, query, header, formData, body)
  let scheme = call_603860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603860.url(scheme.get, call_603860.host, call_603860.base,
                         call_603860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603860, url, valid)

proc call*(call_603861: Call_UpdatePullRequestTitle_603848; body: JsonNode): Recallable =
  ## updatePullRequestTitle
  ## Replaces the title of a pull request.
  ##   body: JObject (required)
  var body_603862 = newJObject()
  if body != nil:
    body_603862 = body
  result = call_603861.call(nil, nil, nil, nil, body_603862)

var updatePullRequestTitle* = Call_UpdatePullRequestTitle_603848(
    name: "updatePullRequestTitle", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestTitle",
    validator: validate_UpdatePullRequestTitle_603849, base: "/",
    url: url_UpdatePullRequestTitle_603850, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRepositoryDescription_603863 = ref object of OpenApiRestCall_602466
proc url_UpdateRepositoryDescription_603865(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRepositoryDescription_603864(path: JsonNode; query: JsonNode;
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
  var valid_603866 = header.getOrDefault("X-Amz-Date")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "X-Amz-Date", valid_603866
  var valid_603867 = header.getOrDefault("X-Amz-Security-Token")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-Security-Token", valid_603867
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603868 = header.getOrDefault("X-Amz-Target")
  valid_603868 = validateParameter(valid_603868, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateRepositoryDescription"))
  if valid_603868 != nil:
    section.add "X-Amz-Target", valid_603868
  var valid_603869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "X-Amz-Content-Sha256", valid_603869
  var valid_603870 = header.getOrDefault("X-Amz-Algorithm")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-Algorithm", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-Signature")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Signature", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-SignedHeaders", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-Credential")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-Credential", valid_603873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603875: Call_UpdateRepositoryDescription_603863; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or changes the comment or description for a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ## 
  let valid = call_603875.validator(path, query, header, formData, body)
  let scheme = call_603875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603875.url(scheme.get, call_603875.host, call_603875.base,
                         call_603875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603875, url, valid)

proc call*(call_603876: Call_UpdateRepositoryDescription_603863; body: JsonNode): Recallable =
  ## updateRepositoryDescription
  ## <p>Sets or changes the comment or description for a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a web page could expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a web page.</p> </note>
  ##   body: JObject (required)
  var body_603877 = newJObject()
  if body != nil:
    body_603877 = body
  result = call_603876.call(nil, nil, nil, nil, body_603877)

var updateRepositoryDescription* = Call_UpdateRepositoryDescription_603863(
    name: "updateRepositoryDescription", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateRepositoryDescription",
    validator: validate_UpdateRepositoryDescription_603864, base: "/",
    url: url_UpdateRepositoryDescription_603865,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRepositoryName_603878 = ref object of OpenApiRestCall_602466
proc url_UpdateRepositoryName_603880(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRepositoryName_603879(path: JsonNode; query: JsonNode;
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
  var valid_603881 = header.getOrDefault("X-Amz-Date")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "X-Amz-Date", valid_603881
  var valid_603882 = header.getOrDefault("X-Amz-Security-Token")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "X-Amz-Security-Token", valid_603882
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603883 = header.getOrDefault("X-Amz-Target")
  valid_603883 = validateParameter(valid_603883, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateRepositoryName"))
  if valid_603883 != nil:
    section.add "X-Amz-Target", valid_603883
  var valid_603884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603884 = validateParameter(valid_603884, JString, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "X-Amz-Content-Sha256", valid_603884
  var valid_603885 = header.getOrDefault("X-Amz-Algorithm")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-Algorithm", valid_603885
  var valid_603886 = header.getOrDefault("X-Amz-Signature")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-Signature", valid_603886
  var valid_603887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "X-Amz-SignedHeaders", valid_603887
  var valid_603888 = header.getOrDefault("X-Amz-Credential")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "X-Amz-Credential", valid_603888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603890: Call_UpdateRepositoryName_603878; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Renames a repository. The repository name must be unique across the calling AWS account. In addition, repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. The suffix ".git" is prohibited. For a full description of the limits on repository names, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html">Limits</a> in the AWS CodeCommit User Guide.
  ## 
  let valid = call_603890.validator(path, query, header, formData, body)
  let scheme = call_603890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603890.url(scheme.get, call_603890.host, call_603890.base,
                         call_603890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603890, url, valid)

proc call*(call_603891: Call_UpdateRepositoryName_603878; body: JsonNode): Recallable =
  ## updateRepositoryName
  ## Renames a repository. The repository name must be unique across the calling AWS account. In addition, repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. The suffix ".git" is prohibited. For a full description of the limits on repository names, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html">Limits</a> in the AWS CodeCommit User Guide.
  ##   body: JObject (required)
  var body_603892 = newJObject()
  if body != nil:
    body_603892 = body
  result = call_603891.call(nil, nil, nil, nil, body_603892)

var updateRepositoryName* = Call_UpdateRepositoryName_603878(
    name: "updateRepositoryName", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateRepositoryName",
    validator: validate_UpdateRepositoryName_603879, base: "/",
    url: url_UpdateRepositoryName_603880, schemes: {Scheme.Https, Scheme.Http})
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
