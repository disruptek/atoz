
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS CodeCommit
## version: 2015-04-13
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS CodeCommit</fullname> <p>This is the <i>AWS CodeCommit API Reference</i>. This reference provides descriptions of the operations and data types for AWS CodeCommit API along with usage examples.</p> <p>You can use the AWS CodeCommit API to work with the following objects:</p> <p>Repositories, by calling the following:</p> <ul> <li> <p> <a>BatchGetRepositories</a>, which returns information about one or more repositories associated with your AWS account.</p> </li> <li> <p> <a>CreateRepository</a>, which creates an AWS CodeCommit repository.</p> </li> <li> <p> <a>DeleteRepository</a>, which deletes an AWS CodeCommit repository.</p> </li> <li> <p> <a>GetRepository</a>, which returns information about a specified repository.</p> </li> <li> <p> <a>ListRepositories</a>, which lists all AWS CodeCommit repositories associated with your AWS account.</p> </li> <li> <p> <a>UpdateRepositoryDescription</a>, which sets or updates the description of the repository.</p> </li> <li> <p> <a>UpdateRepositoryName</a>, which changes the name of the repository. If you change the name of a repository, no other users of that repository can access it until you send them the new HTTPS or SSH URL to use.</p> </li> </ul> <p>Branches, by calling the following:</p> <ul> <li> <p> <a>CreateBranch</a>, which creates a branch in a specified repository.</p> </li> <li> <p> <a>DeleteBranch</a>, which deletes the specified branch in a repository unless it is the default branch.</p> </li> <li> <p> <a>GetBranch</a>, which returns information about a specified branch.</p> </li> <li> <p> <a>ListBranches</a>, which lists all branches for a specified repository.</p> </li> <li> <p> <a>UpdateDefaultBranch</a>, which changes the default branch for a repository.</p> </li> </ul> <p>Files, by calling the following:</p> <ul> <li> <p> <a>DeleteFile</a>, which deletes the content of a specified file from a specified branch.</p> </li> <li> <p> <a>GetBlob</a>, which returns the base-64 encoded content of an individual Git blob object in a repository.</p> </li> <li> <p> <a>GetFile</a>, which returns the base-64 encoded content of a specified file.</p> </li> <li> <p> <a>GetFolder</a>, which returns the contents of a specified folder or directory.</p> </li> <li> <p> <a>PutFile</a>, which adds or modifies a single file in a specified repository and branch.</p> </li> </ul> <p>Commits, by calling the following:</p> <ul> <li> <p> <a>BatchGetCommits</a>, which returns information about one or more commits in a repository.</p> </li> <li> <p> <a>CreateCommit</a>, which creates a commit for changes to a repository.</p> </li> <li> <p> <a>GetCommit</a>, which returns information about a commit, including commit messages and author and committer information.</p> </li> <li> <p> <a>GetDifferences</a>, which returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID, or other fully qualified reference).</p> </li> </ul> <p>Merges, by calling the following:</p> <ul> <li> <p> <a>BatchDescribeMergeConflicts</a>, which returns information about conflicts in a merge between commits in a repository.</p> </li> <li> <p> <a>CreateUnreferencedMergeCommit</a>, which creates an unreferenced commit between two branches or commits for the purpose of comparing them and identifying any potential conflicts.</p> </li> <li> <p> <a>DescribeMergeConflicts</a>, which returns information about merge conflicts between the base, source, and destination versions of a file in a potential merge.</p> </li> <li> <p> <a>GetMergeCommit</a>, which returns information about the merge between a source and destination commit. </p> </li> <li> <p> <a>GetMergeConflicts</a>, which returns information about merge conflicts between the source and destination branch in a pull request.</p> </li> <li> <p> <a>GetMergeOptions</a>, which returns information about the available merge options between two branches or commit specifiers.</p> </li> <li> <p> <a>MergeBranchesByFastForward</a>, which merges two branches using the fast-forward merge option.</p> </li> <li> <p> <a>MergeBranchesBySquash</a>, which merges two branches using the squash merge option.</p> </li> <li> <p> <a>MergeBranchesByThreeWay</a>, which merges two branches using the three-way merge option.</p> </li> </ul> <p>Pull requests, by calling the following:</p> <ul> <li> <p> <a>CreatePullRequest</a>, which creates a pull request in a specified repository.</p> </li> <li> <p> <a>CreatePullRequestApprovalRule</a>, which creates an approval rule for a specified pull request.</p> </li> <li> <p> <a>DeletePullRequestApprovalRule</a>, which deletes an approval rule for a specified pull request.</p> </li> <li> <p> <a>DescribePullRequestEvents</a>, which returns information about one or more pull request events.</p> </li> <li> <p> <a>EvaluatePullRequestApprovalRules</a>, which evaluates whether a pull request has met all the conditions specified in its associated approval rules.</p> </li> <li> <p> <a>GetCommentsForPullRequest</a>, which returns information about comments on a specified pull request.</p> </li> <li> <p> <a>GetPullRequest</a>, which returns information about a specified pull request.</p> </li> <li> <p> <a>GetPullRequestApprovalStates</a>, which returns information about the approval states for a specified pull request.</p> </li> <li> <p> <a>GetPullRequestOverrideState</a>, which returns information about whether approval rules have been set aside (overriden) for a pull request, and if so, the Amazon Resource Name (ARN) of the user or identity that overrode the rules and their requirements for the pull request.</p> </li> <li> <p> <a>ListPullRequests</a>, which lists all pull requests for a repository.</p> </li> <li> <p> <a>MergePullRequestByFastForward</a>, which merges the source destination branch of a pull request into the specified destination branch for that pull request using the fast-forward merge option.</p> </li> <li> <p> <a>MergePullRequestBySquash</a>, which merges the source destination branch of a pull request into the specified destination branch for that pull request using the squash merge option.</p> </li> <li> <p> <a>MergePullRequestByThreeWay</a>. which merges the source destination branch of a pull request into the specified destination branch for that pull request using the three-way merge option.</p> </li> <li> <p> <a>OverridePullRequestApprovalRules</a>, which sets aside all approval rule requirements for a pull request.</p> </li> <li> <p> <a>PostCommentForPullRequest</a>, which posts a comment to a pull request at the specified line, file, or request.</p> </li> <li> <p> <a>UpdatePullRequestApprovalRuleContent</a>, which updates the structure of an approval rule for a pull request.</p> </li> <li> <p> <a>UpdatePullRequestApprovalState</a>, which updates the state of an approval on a pull request.</p> </li> <li> <p> <a>UpdatePullRequestDescription</a>, which updates the description of a pull request.</p> </li> <li> <p> <a>UpdatePullRequestStatus</a>, which updates the status of a pull request.</p> </li> <li> <p> <a>UpdatePullRequestTitle</a>, which updates the title of a pull request.</p> </li> </ul> <p>Approval rule templates, by calling the following:</p> <ul> <li> <p> <a>AssociateApprovalRuleTemplateWithRepository</a>, which associates a template with a specified repository. After the template is associated with a repository, AWS CodeCommit creates approval rules that match the template conditions on every pull request created in the specified repository.</p> </li> <li> <p> <a>BatchAssociateApprovalRuleTemplateWithRepositories</a>, which associates a template with one or more specified repositories. After the template is associated with a repository, AWS CodeCommit creates approval rules that match the template conditions on every pull request created in the specified repositories.</p> </li> <li> <p> <a>BatchDisassociateApprovalRuleTemplateFromRepositories</a>, which removes the association between a template and specified repositories so that approval rules based on the template are not automatically created when pull requests are created in those repositories.</p> </li> <li> <p> <a>CreateApprovalRuleTemplate</a>, which creates a template for approval rules that can then be associated with one or more repositories in your AWS account.</p> </li> <li> <p> <a>DeleteApprovalRuleTemplate</a>, which deletes the specified template. It does not remove approval rules on pull requests already created with the template.</p> </li> <li> <p> <a>DisassociateApprovalRuleTemplateFromRepository</a>, which removes the association between a template and a repository so that approval rules based on the template are not automatically created when pull requests are created in the specified repository.</p> </li> <li> <p> <a>GetApprovalRuleTemplate</a>, which returns information about an approval rule template.</p> </li> <li> <p> <a>ListApprovalRuleTemplates</a>, which lists all approval rule templates in the AWS Region in your AWS account.</p> </li> <li> <p> <a>ListAssociatedApprovalRuleTemplatesForRepository</a>, which lists all approval rule templates that are associated with a specified repository.</p> </li> <li> <p> <a>ListRepositoriesForApprovalRuleTemplate</a>, which lists all repositories associated with the specified approval rule template.</p> </li> <li> <p> <a>UpdateApprovalRuleTemplateDescription</a>, which updates the description of an approval rule template.</p> </li> <li> <p> <a>UpdateApprovalRuleTemplateName</a>, which updates the name of an approval rule template.</p> </li> <li> <p> <a>UpdateApprovalRuleTemplateContent</a>, which updates the content of an approval rule template.</p> </li> </ul> <p>Comments in a repository, by calling the following:</p> <ul> <li> <p> <a>DeleteCommentContent</a>, which deletes the content of a comment on a commit in a repository.</p> </li> <li> <p> <a>GetComment</a>, which returns information about a comment on a commit.</p> </li> <li> <p> <a>GetCommentsForComparedCommit</a>, which returns information about comments on the comparison between two commit specifiers in a repository.</p> </li> <li> <p> <a>PostCommentForComparedCommit</a>, which creates a comment on the comparison between two commit specifiers in a repository.</p> </li> <li> <p> <a>PostCommentReply</a>, which creates a reply to a comment.</p> </li> <li> <p> <a>UpdateComment</a>, which updates the content of a comment on a commit in a repository.</p> </li> </ul> <p>Tags used to tag resources in AWS CodeCommit (not Git tags), by calling the following:</p> <ul> <li> <p> <a>ListTagsForResource</a>, which gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit.</p> </li> <li> <p> <a>TagResource</a>, which adds or updates tags for a resource in AWS CodeCommit.</p> </li> <li> <p> <a>UntagResource</a>, which removes tags for a resource in AWS CodeCommit.</p> </li> </ul> <p>Triggers, by calling the following:</p> <ul> <li> <p> <a>GetRepositoryTriggers</a>, which returns information about triggers configured for a repository.</p> </li> <li> <p> <a>PutRepositoryTriggers</a>, which replaces all triggers for a repository and can be used to create or delete triggers.</p> </li> <li> <p> <a>TestRepositoryTriggers</a>, which tests the functionality of a repository trigger by sending data to the trigger target.</p> </li> </ul> <p>For information about how to use AWS CodeCommit, see the <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html">AWS CodeCommit User Guide</a>.</p>
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateApprovalRuleTemplateWithRepository_601727 = ref object of OpenApiRestCall_601389
proc url_AssociateApprovalRuleTemplateWithRepository_601729(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateApprovalRuleTemplateWithRepository_601728(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an association between an approval rule template and a specified repository. Then, the next time a pull request is created in the repository where the destination reference (if specified) matches the destination reference (branch) for the pull request, an approval rule that matches the template conditions is automatically created for that pull request. If no destination references are specified in the template, an approval rule that matches the template contents is created for all pull requests in that repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601854 = header.getOrDefault("X-Amz-Target")
  valid_601854 = validateParameter(valid_601854, JString, required = true, default = newJString(
      "CodeCommit_20150413.AssociateApprovalRuleTemplateWithRepository"))
  if valid_601854 != nil:
    section.add "X-Amz-Target", valid_601854
  var valid_601855 = header.getOrDefault("X-Amz-Signature")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-Signature", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Content-Sha256", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Date")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Date", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Credential")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Credential", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Security-Token")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Security-Token", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Algorithm")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Algorithm", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-SignedHeaders", valid_601861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601885: Call_AssociateApprovalRuleTemplateWithRepository_601727;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates an association between an approval rule template and a specified repository. Then, the next time a pull request is created in the repository where the destination reference (if specified) matches the destination reference (branch) for the pull request, an approval rule that matches the template conditions is automatically created for that pull request. If no destination references are specified in the template, an approval rule that matches the template contents is created for all pull requests in that repository.
  ## 
  let valid = call_601885.validator(path, query, header, formData, body)
  let scheme = call_601885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601885.url(scheme.get, call_601885.host, call_601885.base,
                         call_601885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601885, url, valid)

proc call*(call_601956: Call_AssociateApprovalRuleTemplateWithRepository_601727;
          body: JsonNode): Recallable =
  ## associateApprovalRuleTemplateWithRepository
  ## Creates an association between an approval rule template and a specified repository. Then, the next time a pull request is created in the repository where the destination reference (if specified) matches the destination reference (branch) for the pull request, an approval rule that matches the template conditions is automatically created for that pull request. If no destination references are specified in the template, an approval rule that matches the template contents is created for all pull requests in that repository.
  ##   body: JObject (required)
  var body_601957 = newJObject()
  if body != nil:
    body_601957 = body
  result = call_601956.call(nil, nil, nil, nil, body_601957)

var associateApprovalRuleTemplateWithRepository* = Call_AssociateApprovalRuleTemplateWithRepository_601727(
    name: "associateApprovalRuleTemplateWithRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.AssociateApprovalRuleTemplateWithRepository",
    validator: validate_AssociateApprovalRuleTemplateWithRepository_601728,
    base: "/", url: url_AssociateApprovalRuleTemplateWithRepository_601729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchAssociateApprovalRuleTemplateWithRepositories_601996 = ref object of OpenApiRestCall_601389
proc url_BatchAssociateApprovalRuleTemplateWithRepositories_601998(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchAssociateApprovalRuleTemplateWithRepositories_601997(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Creates an association between an approval rule template and one or more specified repositories. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601999 = header.getOrDefault("X-Amz-Target")
  valid_601999 = validateParameter(valid_601999, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchAssociateApprovalRuleTemplateWithRepositories"))
  if valid_601999 != nil:
    section.add "X-Amz-Target", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Signature")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Signature", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Content-Sha256", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Date")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Date", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Credential")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Credential", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Security-Token")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Security-Token", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Algorithm")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Algorithm", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-SignedHeaders", valid_602006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_BatchAssociateApprovalRuleTemplateWithRepositories_601996;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates an association between an approval rule template and one or more specified repositories. 
  ## 
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602008, url, valid)

proc call*(call_602009: Call_BatchAssociateApprovalRuleTemplateWithRepositories_601996;
          body: JsonNode): Recallable =
  ## batchAssociateApprovalRuleTemplateWithRepositories
  ## Creates an association between an approval rule template and one or more specified repositories. 
  ##   body: JObject (required)
  var body_602010 = newJObject()
  if body != nil:
    body_602010 = body
  result = call_602009.call(nil, nil, nil, nil, body_602010)

var batchAssociateApprovalRuleTemplateWithRepositories* = Call_BatchAssociateApprovalRuleTemplateWithRepositories_601996(
    name: "batchAssociateApprovalRuleTemplateWithRepositories",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.BatchAssociateApprovalRuleTemplateWithRepositories",
    validator: validate_BatchAssociateApprovalRuleTemplateWithRepositories_601997,
    base: "/", url: url_BatchAssociateApprovalRuleTemplateWithRepositories_601998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDescribeMergeConflicts_602011 = ref object of OpenApiRestCall_601389
proc url_BatchDescribeMergeConflicts_602013(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDescribeMergeConflicts_602012(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602014 = header.getOrDefault("X-Amz-Target")
  valid_602014 = validateParameter(valid_602014, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchDescribeMergeConflicts"))
  if valid_602014 != nil:
    section.add "X-Amz-Target", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Signature")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Signature", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Content-Sha256", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Date")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Date", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Credential")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Credential", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Security-Token")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Security-Token", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Algorithm")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Algorithm", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-SignedHeaders", valid_602021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_BatchDescribeMergeConflicts_602011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy.
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_BatchDescribeMergeConflicts_602011; body: JsonNode): Recallable =
  ## batchDescribeMergeConflicts
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy.
  ##   body: JObject (required)
  var body_602025 = newJObject()
  if body != nil:
    body_602025 = body
  result = call_602024.call(nil, nil, nil, nil, body_602025)

var batchDescribeMergeConflicts* = Call_BatchDescribeMergeConflicts_602011(
    name: "batchDescribeMergeConflicts", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchDescribeMergeConflicts",
    validator: validate_BatchDescribeMergeConflicts_602012, base: "/",
    url: url_BatchDescribeMergeConflicts_602013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDisassociateApprovalRuleTemplateFromRepositories_602026 = ref object of OpenApiRestCall_601389
proc url_BatchDisassociateApprovalRuleTemplateFromRepositories_602028(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDisassociateApprovalRuleTemplateFromRepositories_602027(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Removes the association between an approval rule template and one or more specified repositories. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602029 = header.getOrDefault("X-Amz-Target")
  valid_602029 = validateParameter(valid_602029, JString, required = true, default = newJString("CodeCommit_20150413.BatchDisassociateApprovalRuleTemplateFromRepositories"))
  if valid_602029 != nil:
    section.add "X-Amz-Target", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Signature")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Signature", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Content-Sha256", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Date")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Date", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Credential")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Credential", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Security-Token")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Security-Token", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Algorithm")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Algorithm", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-SignedHeaders", valid_602036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602038: Call_BatchDisassociateApprovalRuleTemplateFromRepositories_602026;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes the association between an approval rule template and one or more specified repositories. 
  ## 
  let valid = call_602038.validator(path, query, header, formData, body)
  let scheme = call_602038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602038.url(scheme.get, call_602038.host, call_602038.base,
                         call_602038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602038, url, valid)

proc call*(call_602039: Call_BatchDisassociateApprovalRuleTemplateFromRepositories_602026;
          body: JsonNode): Recallable =
  ## batchDisassociateApprovalRuleTemplateFromRepositories
  ## Removes the association between an approval rule template and one or more specified repositories. 
  ##   body: JObject (required)
  var body_602040 = newJObject()
  if body != nil:
    body_602040 = body
  result = call_602039.call(nil, nil, nil, nil, body_602040)

var batchDisassociateApprovalRuleTemplateFromRepositories* = Call_BatchDisassociateApprovalRuleTemplateFromRepositories_602026(
    name: "batchDisassociateApprovalRuleTemplateFromRepositories",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.BatchDisassociateApprovalRuleTemplateFromRepositories",
    validator: validate_BatchDisassociateApprovalRuleTemplateFromRepositories_602027,
    base: "/", url: url_BatchDisassociateApprovalRuleTemplateFromRepositories_602028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetCommits_602041 = ref object of OpenApiRestCall_601389
proc url_BatchGetCommits_602043(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetCommits_602042(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602044 = header.getOrDefault("X-Amz-Target")
  valid_602044 = validateParameter(valid_602044, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchGetCommits"))
  if valid_602044 != nil:
    section.add "X-Amz-Target", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Signature")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Signature", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Content-Sha256", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Date")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Date", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Credential")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Credential", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Security-Token")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Security-Token", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Algorithm")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Algorithm", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-SignedHeaders", valid_602051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602053: Call_BatchGetCommits_602041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the contents of one or more commits in a repository.
  ## 
  let valid = call_602053.validator(path, query, header, formData, body)
  let scheme = call_602053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602053.url(scheme.get, call_602053.host, call_602053.base,
                         call_602053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602053, url, valid)

proc call*(call_602054: Call_BatchGetCommits_602041; body: JsonNode): Recallable =
  ## batchGetCommits
  ## Returns information about the contents of one or more commits in a repository.
  ##   body: JObject (required)
  var body_602055 = newJObject()
  if body != nil:
    body_602055 = body
  result = call_602054.call(nil, nil, nil, nil, body_602055)

var batchGetCommits* = Call_BatchGetCommits_602041(name: "batchGetCommits",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchGetCommits",
    validator: validate_BatchGetCommits_602042, base: "/", url: url_BatchGetCommits_602043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetRepositories_602056 = ref object of OpenApiRestCall_601389
proc url_BatchGetRepositories_602058(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetRepositories_602057(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about one or more repositories.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602059 = header.getOrDefault("X-Amz-Target")
  valid_602059 = validateParameter(valid_602059, JString, required = true, default = newJString(
      "CodeCommit_20150413.BatchGetRepositories"))
  if valid_602059 != nil:
    section.add "X-Amz-Target", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Signature")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Signature", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Content-Sha256", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Date")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Date", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Credential")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Credential", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Security-Token")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Security-Token", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Algorithm")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Algorithm", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-SignedHeaders", valid_602066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602068: Call_BatchGetRepositories_602056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about one or more repositories.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602068, url, valid)

proc call*(call_602069: Call_BatchGetRepositories_602056; body: JsonNode): Recallable =
  ## batchGetRepositories
  ## <p>Returns information about one or more repositories.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ##   body: JObject (required)
  var body_602070 = newJObject()
  if body != nil:
    body_602070 = body
  result = call_602069.call(nil, nil, nil, nil, body_602070)

var batchGetRepositories* = Call_BatchGetRepositories_602056(
    name: "batchGetRepositories", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.BatchGetRepositories",
    validator: validate_BatchGetRepositories_602057, base: "/",
    url: url_BatchGetRepositories_602058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApprovalRuleTemplate_602071 = ref object of OpenApiRestCall_601389
proc url_CreateApprovalRuleTemplate_602073(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApprovalRuleTemplate_602072(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a template for approval rules that can then be associated with one or more repositories in your AWS account. When you associate a template with a repository, AWS CodeCommit creates an approval rule that matches the conditions of the template for all pull requests that meet the conditions of the template. For more information, see <a>AssociateApprovalRuleTemplateWithRepository</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602074 = header.getOrDefault("X-Amz-Target")
  valid_602074 = validateParameter(valid_602074, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateApprovalRuleTemplate"))
  if valid_602074 != nil:
    section.add "X-Amz-Target", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Signature")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Signature", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Content-Sha256", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Date")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Date", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Credential")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Credential", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Security-Token")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Security-Token", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Algorithm")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Algorithm", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-SignedHeaders", valid_602081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602083: Call_CreateApprovalRuleTemplate_602071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a template for approval rules that can then be associated with one or more repositories in your AWS account. When you associate a template with a repository, AWS CodeCommit creates an approval rule that matches the conditions of the template for all pull requests that meet the conditions of the template. For more information, see <a>AssociateApprovalRuleTemplateWithRepository</a>.
  ## 
  let valid = call_602083.validator(path, query, header, formData, body)
  let scheme = call_602083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602083.url(scheme.get, call_602083.host, call_602083.base,
                         call_602083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602083, url, valid)

proc call*(call_602084: Call_CreateApprovalRuleTemplate_602071; body: JsonNode): Recallable =
  ## createApprovalRuleTemplate
  ## Creates a template for approval rules that can then be associated with one or more repositories in your AWS account. When you associate a template with a repository, AWS CodeCommit creates an approval rule that matches the conditions of the template for all pull requests that meet the conditions of the template. For more information, see <a>AssociateApprovalRuleTemplateWithRepository</a>.
  ##   body: JObject (required)
  var body_602085 = newJObject()
  if body != nil:
    body_602085 = body
  result = call_602084.call(nil, nil, nil, nil, body_602085)

var createApprovalRuleTemplate* = Call_CreateApprovalRuleTemplate_602071(
    name: "createApprovalRuleTemplate", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateApprovalRuleTemplate",
    validator: validate_CreateApprovalRuleTemplate_602072, base: "/",
    url: url_CreateApprovalRuleTemplate_602073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateBranch_602086 = ref object of OpenApiRestCall_601389
proc url_CreateBranch_602088(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateBranch_602087(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a branch in a repository and points the branch to a commit.</p> <note> <p>Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602089 = header.getOrDefault("X-Amz-Target")
  valid_602089 = validateParameter(valid_602089, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateBranch"))
  if valid_602089 != nil:
    section.add "X-Amz-Target", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Signature")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Signature", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Content-Sha256", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Date")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Date", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Credential")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Credential", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Security-Token")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Security-Token", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Algorithm")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Algorithm", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-SignedHeaders", valid_602096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602098: Call_CreateBranch_602086; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a branch in a repository and points the branch to a commit.</p> <note> <p>Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.</p> </note>
  ## 
  let valid = call_602098.validator(path, query, header, formData, body)
  let scheme = call_602098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602098.url(scheme.get, call_602098.host, call_602098.base,
                         call_602098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602098, url, valid)

proc call*(call_602099: Call_CreateBranch_602086; body: JsonNode): Recallable =
  ## createBranch
  ## <p>Creates a branch in a repository and points the branch to a commit.</p> <note> <p>Calling the create branch operation does not set a repository's default branch. To do this, call the update default branch operation.</p> </note>
  ##   body: JObject (required)
  var body_602100 = newJObject()
  if body != nil:
    body_602100 = body
  result = call_602099.call(nil, nil, nil, nil, body_602100)

var createBranch* = Call_CreateBranch_602086(name: "createBranch",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateBranch",
    validator: validate_CreateBranch_602087, base: "/", url: url_CreateBranch_602088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCommit_602101 = ref object of OpenApiRestCall_601389
proc url_CreateCommit_602103(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCommit_602102(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602104 = header.getOrDefault("X-Amz-Target")
  valid_602104 = validateParameter(valid_602104, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateCommit"))
  if valid_602104 != nil:
    section.add "X-Amz-Target", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Signature")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Signature", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Content-Sha256", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Date")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Date", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Credential")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Credential", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Security-Token")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Security-Token", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Algorithm")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Algorithm", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-SignedHeaders", valid_602111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602113: Call_CreateCommit_602101; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a commit for a repository on the tip of a specified branch.
  ## 
  let valid = call_602113.validator(path, query, header, formData, body)
  let scheme = call_602113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602113.url(scheme.get, call_602113.host, call_602113.base,
                         call_602113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602113, url, valid)

proc call*(call_602114: Call_CreateCommit_602101; body: JsonNode): Recallable =
  ## createCommit
  ## Creates a commit for a repository on the tip of a specified branch.
  ##   body: JObject (required)
  var body_602115 = newJObject()
  if body != nil:
    body_602115 = body
  result = call_602114.call(nil, nil, nil, nil, body_602115)

var createCommit* = Call_CreateCommit_602101(name: "createCommit",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateCommit",
    validator: validate_CreateCommit_602102, base: "/", url: url_CreateCommit_602103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePullRequest_602116 = ref object of OpenApiRestCall_601389
proc url_CreatePullRequest_602118(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePullRequest_602117(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602119 = header.getOrDefault("X-Amz-Target")
  valid_602119 = validateParameter(valid_602119, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreatePullRequest"))
  if valid_602119 != nil:
    section.add "X-Amz-Target", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Signature")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Signature", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Content-Sha256", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Date")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Date", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Credential")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Credential", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Security-Token")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Security-Token", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Algorithm")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Algorithm", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-SignedHeaders", valid_602126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602128: Call_CreatePullRequest_602116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a pull request in the specified repository.
  ## 
  let valid = call_602128.validator(path, query, header, formData, body)
  let scheme = call_602128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602128.url(scheme.get, call_602128.host, call_602128.base,
                         call_602128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602128, url, valid)

proc call*(call_602129: Call_CreatePullRequest_602116; body: JsonNode): Recallable =
  ## createPullRequest
  ## Creates a pull request in the specified repository.
  ##   body: JObject (required)
  var body_602130 = newJObject()
  if body != nil:
    body_602130 = body
  result = call_602129.call(nil, nil, nil, nil, body_602130)

var createPullRequest* = Call_CreatePullRequest_602116(name: "createPullRequest",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreatePullRequest",
    validator: validate_CreatePullRequest_602117, base: "/",
    url: url_CreatePullRequest_602118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePullRequestApprovalRule_602131 = ref object of OpenApiRestCall_601389
proc url_CreatePullRequestApprovalRule_602133(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePullRequestApprovalRule_602132(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an approval rule for a pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602134 = header.getOrDefault("X-Amz-Target")
  valid_602134 = validateParameter(valid_602134, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreatePullRequestApprovalRule"))
  if valid_602134 != nil:
    section.add "X-Amz-Target", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Signature")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Signature", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Content-Sha256", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Date")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Date", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Credential")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Credential", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Security-Token")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Security-Token", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Algorithm")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Algorithm", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-SignedHeaders", valid_602141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602143: Call_CreatePullRequestApprovalRule_602131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an approval rule for a pull request.
  ## 
  let valid = call_602143.validator(path, query, header, formData, body)
  let scheme = call_602143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602143.url(scheme.get, call_602143.host, call_602143.base,
                         call_602143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602143, url, valid)

proc call*(call_602144: Call_CreatePullRequestApprovalRule_602131; body: JsonNode): Recallable =
  ## createPullRequestApprovalRule
  ## Creates an approval rule for a pull request.
  ##   body: JObject (required)
  var body_602145 = newJObject()
  if body != nil:
    body_602145 = body
  result = call_602144.call(nil, nil, nil, nil, body_602145)

var createPullRequestApprovalRule* = Call_CreatePullRequestApprovalRule_602131(
    name: "createPullRequestApprovalRule", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreatePullRequestApprovalRule",
    validator: validate_CreatePullRequestApprovalRule_602132, base: "/",
    url: url_CreatePullRequestApprovalRule_602133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRepository_602146 = ref object of OpenApiRestCall_601389
proc url_CreateRepository_602148(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRepository_602147(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602149 = header.getOrDefault("X-Amz-Target")
  valid_602149 = validateParameter(valid_602149, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateRepository"))
  if valid_602149 != nil:
    section.add "X-Amz-Target", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Signature")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Signature", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Content-Sha256", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Date")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Date", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Credential")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Credential", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Security-Token")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Security-Token", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Algorithm")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Algorithm", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-SignedHeaders", valid_602156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602158: Call_CreateRepository_602146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new, empty repository.
  ## 
  let valid = call_602158.validator(path, query, header, formData, body)
  let scheme = call_602158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602158.url(scheme.get, call_602158.host, call_602158.base,
                         call_602158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602158, url, valid)

proc call*(call_602159: Call_CreateRepository_602146; body: JsonNode): Recallable =
  ## createRepository
  ## Creates a new, empty repository.
  ##   body: JObject (required)
  var body_602160 = newJObject()
  if body != nil:
    body_602160 = body
  result = call_602159.call(nil, nil, nil, nil, body_602160)

var createRepository* = Call_CreateRepository_602146(name: "createRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateRepository",
    validator: validate_CreateRepository_602147, base: "/",
    url: url_CreateRepository_602148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateUnreferencedMergeCommit_602161 = ref object of OpenApiRestCall_601389
proc url_CreateUnreferencedMergeCommit_602163(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateUnreferencedMergeCommit_602162(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an unreferenced commit that represents the result of merging two branches using a specified merge strategy. This can help you determine the outcome of a potential merge. This API cannot be used with the fast-forward merge strategy because that strategy does not create a merge commit.</p> <note> <p>This unreferenced merge commit can only be accessed using the GetCommit API or through git commands such as git fetch. To retrieve this commit, you must specify its commit ID or otherwise reference it.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602164 = header.getOrDefault("X-Amz-Target")
  valid_602164 = validateParameter(valid_602164, JString, required = true, default = newJString(
      "CodeCommit_20150413.CreateUnreferencedMergeCommit"))
  if valid_602164 != nil:
    section.add "X-Amz-Target", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Signature")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Signature", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Content-Sha256", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Date")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Date", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Credential")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Credential", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Security-Token")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Security-Token", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Algorithm")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Algorithm", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-SignedHeaders", valid_602171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602173: Call_CreateUnreferencedMergeCommit_602161; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an unreferenced commit that represents the result of merging two branches using a specified merge strategy. This can help you determine the outcome of a potential merge. This API cannot be used with the fast-forward merge strategy because that strategy does not create a merge commit.</p> <note> <p>This unreferenced merge commit can only be accessed using the GetCommit API or through git commands such as git fetch. To retrieve this commit, you must specify its commit ID or otherwise reference it.</p> </note>
  ## 
  let valid = call_602173.validator(path, query, header, formData, body)
  let scheme = call_602173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602173.url(scheme.get, call_602173.host, call_602173.base,
                         call_602173.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602173, url, valid)

proc call*(call_602174: Call_CreateUnreferencedMergeCommit_602161; body: JsonNode): Recallable =
  ## createUnreferencedMergeCommit
  ## <p>Creates an unreferenced commit that represents the result of merging two branches using a specified merge strategy. This can help you determine the outcome of a potential merge. This API cannot be used with the fast-forward merge strategy because that strategy does not create a merge commit.</p> <note> <p>This unreferenced merge commit can only be accessed using the GetCommit API or through git commands such as git fetch. To retrieve this commit, you must specify its commit ID or otherwise reference it.</p> </note>
  ##   body: JObject (required)
  var body_602175 = newJObject()
  if body != nil:
    body_602175 = body
  result = call_602174.call(nil, nil, nil, nil, body_602175)

var createUnreferencedMergeCommit* = Call_CreateUnreferencedMergeCommit_602161(
    name: "createUnreferencedMergeCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.CreateUnreferencedMergeCommit",
    validator: validate_CreateUnreferencedMergeCommit_602162, base: "/",
    url: url_CreateUnreferencedMergeCommit_602163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApprovalRuleTemplate_602176 = ref object of OpenApiRestCall_601389
proc url_DeleteApprovalRuleTemplate_602178(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApprovalRuleTemplate_602177(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified approval rule template. Deleting a template does not remove approval rules on pull requests already created with the template.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602179 = header.getOrDefault("X-Amz-Target")
  valid_602179 = validateParameter(valid_602179, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteApprovalRuleTemplate"))
  if valid_602179 != nil:
    section.add "X-Amz-Target", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Signature")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Signature", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Content-Sha256", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Date")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Date", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Credential")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Credential", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Security-Token")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Security-Token", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Algorithm")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Algorithm", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-SignedHeaders", valid_602186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602188: Call_DeleteApprovalRuleTemplate_602176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified approval rule template. Deleting a template does not remove approval rules on pull requests already created with the template.
  ## 
  let valid = call_602188.validator(path, query, header, formData, body)
  let scheme = call_602188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602188.url(scheme.get, call_602188.host, call_602188.base,
                         call_602188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602188, url, valid)

proc call*(call_602189: Call_DeleteApprovalRuleTemplate_602176; body: JsonNode): Recallable =
  ## deleteApprovalRuleTemplate
  ## Deletes a specified approval rule template. Deleting a template does not remove approval rules on pull requests already created with the template.
  ##   body: JObject (required)
  var body_602190 = newJObject()
  if body != nil:
    body_602190 = body
  result = call_602189.call(nil, nil, nil, nil, body_602190)

var deleteApprovalRuleTemplate* = Call_DeleteApprovalRuleTemplate_602176(
    name: "deleteApprovalRuleTemplate", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteApprovalRuleTemplate",
    validator: validate_DeleteApprovalRuleTemplate_602177, base: "/",
    url: url_DeleteApprovalRuleTemplate_602178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBranch_602191 = ref object of OpenApiRestCall_601389
proc url_DeleteBranch_602193(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteBranch_602192(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602194 = header.getOrDefault("X-Amz-Target")
  valid_602194 = validateParameter(valid_602194, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteBranch"))
  if valid_602194 != nil:
    section.add "X-Amz-Target", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Signature")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Signature", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Content-Sha256", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Date")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Date", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Credential")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Credential", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Security-Token")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Security-Token", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Algorithm")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Algorithm", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-SignedHeaders", valid_602201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602203: Call_DeleteBranch_602191; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a branch from a repository, unless that branch is the default branch for the repository. 
  ## 
  let valid = call_602203.validator(path, query, header, formData, body)
  let scheme = call_602203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602203.url(scheme.get, call_602203.host, call_602203.base,
                         call_602203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602203, url, valid)

proc call*(call_602204: Call_DeleteBranch_602191; body: JsonNode): Recallable =
  ## deleteBranch
  ## Deletes a branch from a repository, unless that branch is the default branch for the repository. 
  ##   body: JObject (required)
  var body_602205 = newJObject()
  if body != nil:
    body_602205 = body
  result = call_602204.call(nil, nil, nil, nil, body_602205)

var deleteBranch* = Call_DeleteBranch_602191(name: "deleteBranch",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteBranch",
    validator: validate_DeleteBranch_602192, base: "/", url: url_DeleteBranch_602193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCommentContent_602206 = ref object of OpenApiRestCall_601389
proc url_DeleteCommentContent_602208(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteCommentContent_602207(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602209 = header.getOrDefault("X-Amz-Target")
  valid_602209 = validateParameter(valid_602209, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteCommentContent"))
  if valid_602209 != nil:
    section.add "X-Amz-Target", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Signature")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Signature", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Content-Sha256", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Date")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Date", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Credential")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Credential", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Security-Token")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Security-Token", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Algorithm")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Algorithm", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-SignedHeaders", valid_602216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602218: Call_DeleteCommentContent_602206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the content of a comment made on a change, file, or commit in a repository.
  ## 
  let valid = call_602218.validator(path, query, header, formData, body)
  let scheme = call_602218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602218.url(scheme.get, call_602218.host, call_602218.base,
                         call_602218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602218, url, valid)

proc call*(call_602219: Call_DeleteCommentContent_602206; body: JsonNode): Recallable =
  ## deleteCommentContent
  ## Deletes the content of a comment made on a change, file, or commit in a repository.
  ##   body: JObject (required)
  var body_602220 = newJObject()
  if body != nil:
    body_602220 = body
  result = call_602219.call(nil, nil, nil, nil, body_602220)

var deleteCommentContent* = Call_DeleteCommentContent_602206(
    name: "deleteCommentContent", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteCommentContent",
    validator: validate_DeleteCommentContent_602207, base: "/",
    url: url_DeleteCommentContent_602208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFile_602221 = ref object of OpenApiRestCall_601389
proc url_DeleteFile_602223(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFile_602222(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a specified file from a specified branch. A commit is created on the branch that contains the revision. The file still exists in the commits earlier to the commit that contains the deletion.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602224 = header.getOrDefault("X-Amz-Target")
  valid_602224 = validateParameter(valid_602224, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteFile"))
  if valid_602224 != nil:
    section.add "X-Amz-Target", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Signature")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Signature", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Content-Sha256", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Date")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Date", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Credential")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Credential", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Security-Token")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Security-Token", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Algorithm")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Algorithm", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-SignedHeaders", valid_602231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602233: Call_DeleteFile_602221; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a specified file from a specified branch. A commit is created on the branch that contains the revision. The file still exists in the commits earlier to the commit that contains the deletion.
  ## 
  let valid = call_602233.validator(path, query, header, formData, body)
  let scheme = call_602233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602233.url(scheme.get, call_602233.host, call_602233.base,
                         call_602233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602233, url, valid)

proc call*(call_602234: Call_DeleteFile_602221; body: JsonNode): Recallable =
  ## deleteFile
  ## Deletes a specified file from a specified branch. A commit is created on the branch that contains the revision. The file still exists in the commits earlier to the commit that contains the deletion.
  ##   body: JObject (required)
  var body_602235 = newJObject()
  if body != nil:
    body_602235 = body
  result = call_602234.call(nil, nil, nil, nil, body_602235)

var deleteFile* = Call_DeleteFile_602221(name: "deleteFile",
                                      meth: HttpMethod.HttpPost,
                                      host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.DeleteFile",
                                      validator: validate_DeleteFile_602222,
                                      base: "/", url: url_DeleteFile_602223,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePullRequestApprovalRule_602236 = ref object of OpenApiRestCall_601389
proc url_DeletePullRequestApprovalRule_602238(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePullRequestApprovalRule_602237(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an approval rule from a specified pull request. Approval rules can be deleted from a pull request only if the pull request is open, and if the approval rule was created specifically for a pull request and not generated from an approval rule template associated with the repository where the pull request was created. You cannot delete an approval rule from a merged or closed pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602239 = header.getOrDefault("X-Amz-Target")
  valid_602239 = validateParameter(valid_602239, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeletePullRequestApprovalRule"))
  if valid_602239 != nil:
    section.add "X-Amz-Target", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Signature")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Signature", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Content-Sha256", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Date")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Date", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Credential")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Credential", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Security-Token")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Security-Token", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Algorithm")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Algorithm", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-SignedHeaders", valid_602246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602248: Call_DeletePullRequestApprovalRule_602236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an approval rule from a specified pull request. Approval rules can be deleted from a pull request only if the pull request is open, and if the approval rule was created specifically for a pull request and not generated from an approval rule template associated with the repository where the pull request was created. You cannot delete an approval rule from a merged or closed pull request.
  ## 
  let valid = call_602248.validator(path, query, header, formData, body)
  let scheme = call_602248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602248.url(scheme.get, call_602248.host, call_602248.base,
                         call_602248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602248, url, valid)

proc call*(call_602249: Call_DeletePullRequestApprovalRule_602236; body: JsonNode): Recallable =
  ## deletePullRequestApprovalRule
  ## Deletes an approval rule from a specified pull request. Approval rules can be deleted from a pull request only if the pull request is open, and if the approval rule was created specifically for a pull request and not generated from an approval rule template associated with the repository where the pull request was created. You cannot delete an approval rule from a merged or closed pull request.
  ##   body: JObject (required)
  var body_602250 = newJObject()
  if body != nil:
    body_602250 = body
  result = call_602249.call(nil, nil, nil, nil, body_602250)

var deletePullRequestApprovalRule* = Call_DeletePullRequestApprovalRule_602236(
    name: "deletePullRequestApprovalRule", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeletePullRequestApprovalRule",
    validator: validate_DeletePullRequestApprovalRule_602237, base: "/",
    url: url_DeletePullRequestApprovalRule_602238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRepository_602251 = ref object of OpenApiRestCall_601389
proc url_DeleteRepository_602253(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRepository_602252(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes a repository. If a specified repository was already deleted, a null repository ID is returned.</p> <important> <p>Deleting a repository also deletes all associated objects and metadata. After a repository is deleted, all future push calls to the deleted repository fail.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602254 = header.getOrDefault("X-Amz-Target")
  valid_602254 = validateParameter(valid_602254, JString, required = true, default = newJString(
      "CodeCommit_20150413.DeleteRepository"))
  if valid_602254 != nil:
    section.add "X-Amz-Target", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Signature")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Signature", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Content-Sha256", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Date")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Date", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Credential")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Credential", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Security-Token")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Security-Token", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Algorithm")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Algorithm", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-SignedHeaders", valid_602261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602263: Call_DeleteRepository_602251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a repository. If a specified repository was already deleted, a null repository ID is returned.</p> <important> <p>Deleting a repository also deletes all associated objects and metadata. After a repository is deleted, all future push calls to the deleted repository fail.</p> </important>
  ## 
  let valid = call_602263.validator(path, query, header, formData, body)
  let scheme = call_602263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602263.url(scheme.get, call_602263.host, call_602263.base,
                         call_602263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602263, url, valid)

proc call*(call_602264: Call_DeleteRepository_602251; body: JsonNode): Recallable =
  ## deleteRepository
  ## <p>Deletes a repository. If a specified repository was already deleted, a null repository ID is returned.</p> <important> <p>Deleting a repository also deletes all associated objects and metadata. After a repository is deleted, all future push calls to the deleted repository fail.</p> </important>
  ##   body: JObject (required)
  var body_602265 = newJObject()
  if body != nil:
    body_602265 = body
  result = call_602264.call(nil, nil, nil, nil, body_602265)

var deleteRepository* = Call_DeleteRepository_602251(name: "deleteRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DeleteRepository",
    validator: validate_DeleteRepository_602252, base: "/",
    url: url_DeleteRepository_602253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMergeConflicts_602266 = ref object of OpenApiRestCall_601389
proc url_DescribeMergeConflicts_602268(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMergeConflicts_602267(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy. If the merge option for the attempted merge is specified as FAST_FORWARD_MERGE, an exception is thrown.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxMergeHunks: JString
  ##                : Pagination limit
  section = newJObject()
  var valid_602269 = query.getOrDefault("nextToken")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "nextToken", valid_602269
  var valid_602270 = query.getOrDefault("maxMergeHunks")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "maxMergeHunks", valid_602270
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602271 = header.getOrDefault("X-Amz-Target")
  valid_602271 = validateParameter(valid_602271, JString, required = true, default = newJString(
      "CodeCommit_20150413.DescribeMergeConflicts"))
  if valid_602271 != nil:
    section.add "X-Amz-Target", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Signature")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Signature", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Content-Sha256", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-Date")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Date", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Credential")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Credential", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-Security-Token")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Security-Token", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-Algorithm")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-Algorithm", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-SignedHeaders", valid_602278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602280: Call_DescribeMergeConflicts_602266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy. If the merge option for the attempted merge is specified as FAST_FORWARD_MERGE, an exception is thrown.
  ## 
  let valid = call_602280.validator(path, query, header, formData, body)
  let scheme = call_602280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602280.url(scheme.get, call_602280.host, call_602280.base,
                         call_602280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602280, url, valid)

proc call*(call_602281: Call_DescribeMergeConflicts_602266; body: JsonNode;
          nextToken: string = ""; maxMergeHunks: string = ""): Recallable =
  ## describeMergeConflicts
  ## Returns information about one or more merge conflicts in the attempted merge of two commit specifiers using the squash or three-way merge strategy. If the merge option for the attempted merge is specified as FAST_FORWARD_MERGE, an exception is thrown.
  ##   nextToken: string
  ##            : Pagination token
  ##   maxMergeHunks: string
  ##                : Pagination limit
  ##   body: JObject (required)
  var query_602282 = newJObject()
  var body_602283 = newJObject()
  add(query_602282, "nextToken", newJString(nextToken))
  add(query_602282, "maxMergeHunks", newJString(maxMergeHunks))
  if body != nil:
    body_602283 = body
  result = call_602281.call(nil, query_602282, nil, nil, body_602283)

var describeMergeConflicts* = Call_DescribeMergeConflicts_602266(
    name: "describeMergeConflicts", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DescribeMergeConflicts",
    validator: validate_DescribeMergeConflicts_602267, base: "/",
    url: url_DescribeMergeConflicts_602268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePullRequestEvents_602285 = ref object of OpenApiRestCall_601389
proc url_DescribePullRequestEvents_602287(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePullRequestEvents_602286(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about one or more pull request events.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_602288 = query.getOrDefault("nextToken")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "nextToken", valid_602288
  var valid_602289 = query.getOrDefault("maxResults")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "maxResults", valid_602289
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602290 = header.getOrDefault("X-Amz-Target")
  valid_602290 = validateParameter(valid_602290, JString, required = true, default = newJString(
      "CodeCommit_20150413.DescribePullRequestEvents"))
  if valid_602290 != nil:
    section.add "X-Amz-Target", valid_602290
  var valid_602291 = header.getOrDefault("X-Amz-Signature")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "X-Amz-Signature", valid_602291
  var valid_602292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-Content-Sha256", valid_602292
  var valid_602293 = header.getOrDefault("X-Amz-Date")
  valid_602293 = validateParameter(valid_602293, JString, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "X-Amz-Date", valid_602293
  var valid_602294 = header.getOrDefault("X-Amz-Credential")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "X-Amz-Credential", valid_602294
  var valid_602295 = header.getOrDefault("X-Amz-Security-Token")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Security-Token", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-Algorithm")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Algorithm", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-SignedHeaders", valid_602297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602299: Call_DescribePullRequestEvents_602285; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about one or more pull request events.
  ## 
  let valid = call_602299.validator(path, query, header, formData, body)
  let scheme = call_602299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602299.url(scheme.get, call_602299.host, call_602299.base,
                         call_602299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602299, url, valid)

proc call*(call_602300: Call_DescribePullRequestEvents_602285; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describePullRequestEvents
  ## Returns information about one or more pull request events.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602301 = newJObject()
  var body_602302 = newJObject()
  add(query_602301, "nextToken", newJString(nextToken))
  if body != nil:
    body_602302 = body
  add(query_602301, "maxResults", newJString(maxResults))
  result = call_602300.call(nil, query_602301, nil, nil, body_602302)

var describePullRequestEvents* = Call_DescribePullRequestEvents_602285(
    name: "describePullRequestEvents", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.DescribePullRequestEvents",
    validator: validate_DescribePullRequestEvents_602286, base: "/",
    url: url_DescribePullRequestEvents_602287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateApprovalRuleTemplateFromRepository_602303 = ref object of OpenApiRestCall_601389
proc url_DisassociateApprovalRuleTemplateFromRepository_602305(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateApprovalRuleTemplateFromRepository_602304(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Removes the association between a template and a repository so that approval rules based on the template are not automatically created when pull requests are created in the specified repository. This does not delete any approval rules previously created for pull requests through the template association.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602306 = header.getOrDefault("X-Amz-Target")
  valid_602306 = validateParameter(valid_602306, JString, required = true, default = newJString(
      "CodeCommit_20150413.DisassociateApprovalRuleTemplateFromRepository"))
  if valid_602306 != nil:
    section.add "X-Amz-Target", valid_602306
  var valid_602307 = header.getOrDefault("X-Amz-Signature")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "X-Amz-Signature", valid_602307
  var valid_602308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "X-Amz-Content-Sha256", valid_602308
  var valid_602309 = header.getOrDefault("X-Amz-Date")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "X-Amz-Date", valid_602309
  var valid_602310 = header.getOrDefault("X-Amz-Credential")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Credential", valid_602310
  var valid_602311 = header.getOrDefault("X-Amz-Security-Token")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Security-Token", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-Algorithm")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Algorithm", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-SignedHeaders", valid_602313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602315: Call_DisassociateApprovalRuleTemplateFromRepository_602303;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes the association between a template and a repository so that approval rules based on the template are not automatically created when pull requests are created in the specified repository. This does not delete any approval rules previously created for pull requests through the template association.
  ## 
  let valid = call_602315.validator(path, query, header, formData, body)
  let scheme = call_602315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602315.url(scheme.get, call_602315.host, call_602315.base,
                         call_602315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602315, url, valid)

proc call*(call_602316: Call_DisassociateApprovalRuleTemplateFromRepository_602303;
          body: JsonNode): Recallable =
  ## disassociateApprovalRuleTemplateFromRepository
  ## Removes the association between a template and a repository so that approval rules based on the template are not automatically created when pull requests are created in the specified repository. This does not delete any approval rules previously created for pull requests through the template association.
  ##   body: JObject (required)
  var body_602317 = newJObject()
  if body != nil:
    body_602317 = body
  result = call_602316.call(nil, nil, nil, nil, body_602317)

var disassociateApprovalRuleTemplateFromRepository* = Call_DisassociateApprovalRuleTemplateFromRepository_602303(
    name: "disassociateApprovalRuleTemplateFromRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.DisassociateApprovalRuleTemplateFromRepository",
    validator: validate_DisassociateApprovalRuleTemplateFromRepository_602304,
    base: "/", url: url_DisassociateApprovalRuleTemplateFromRepository_602305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_EvaluatePullRequestApprovalRules_602318 = ref object of OpenApiRestCall_601389
proc url_EvaluatePullRequestApprovalRules_602320(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_EvaluatePullRequestApprovalRules_602319(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Evaluates whether a pull request has met all the conditions specified in its associated approval rules.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602321 = header.getOrDefault("X-Amz-Target")
  valid_602321 = validateParameter(valid_602321, JString, required = true, default = newJString(
      "CodeCommit_20150413.EvaluatePullRequestApprovalRules"))
  if valid_602321 != nil:
    section.add "X-Amz-Target", valid_602321
  var valid_602322 = header.getOrDefault("X-Amz-Signature")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Signature", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-Content-Sha256", valid_602323
  var valid_602324 = header.getOrDefault("X-Amz-Date")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "X-Amz-Date", valid_602324
  var valid_602325 = header.getOrDefault("X-Amz-Credential")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "X-Amz-Credential", valid_602325
  var valid_602326 = header.getOrDefault("X-Amz-Security-Token")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-Security-Token", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-Algorithm")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-Algorithm", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-SignedHeaders", valid_602328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602330: Call_EvaluatePullRequestApprovalRules_602318;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Evaluates whether a pull request has met all the conditions specified in its associated approval rules.
  ## 
  let valid = call_602330.validator(path, query, header, formData, body)
  let scheme = call_602330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602330.url(scheme.get, call_602330.host, call_602330.base,
                         call_602330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602330, url, valid)

proc call*(call_602331: Call_EvaluatePullRequestApprovalRules_602318;
          body: JsonNode): Recallable =
  ## evaluatePullRequestApprovalRules
  ## Evaluates whether a pull request has met all the conditions specified in its associated approval rules.
  ##   body: JObject (required)
  var body_602332 = newJObject()
  if body != nil:
    body_602332 = body
  result = call_602331.call(nil, nil, nil, nil, body_602332)

var evaluatePullRequestApprovalRules* = Call_EvaluatePullRequestApprovalRules_602318(
    name: "evaluatePullRequestApprovalRules", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.EvaluatePullRequestApprovalRules",
    validator: validate_EvaluatePullRequestApprovalRules_602319, base: "/",
    url: url_EvaluatePullRequestApprovalRules_602320,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApprovalRuleTemplate_602333 = ref object of OpenApiRestCall_601389
proc url_GetApprovalRuleTemplate_602335(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApprovalRuleTemplate_602334(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a specified approval rule template.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602336 = header.getOrDefault("X-Amz-Target")
  valid_602336 = validateParameter(valid_602336, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetApprovalRuleTemplate"))
  if valid_602336 != nil:
    section.add "X-Amz-Target", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-Signature")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-Signature", valid_602337
  var valid_602338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-Content-Sha256", valid_602338
  var valid_602339 = header.getOrDefault("X-Amz-Date")
  valid_602339 = validateParameter(valid_602339, JString, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "X-Amz-Date", valid_602339
  var valid_602340 = header.getOrDefault("X-Amz-Credential")
  valid_602340 = validateParameter(valid_602340, JString, required = false,
                                 default = nil)
  if valid_602340 != nil:
    section.add "X-Amz-Credential", valid_602340
  var valid_602341 = header.getOrDefault("X-Amz-Security-Token")
  valid_602341 = validateParameter(valid_602341, JString, required = false,
                                 default = nil)
  if valid_602341 != nil:
    section.add "X-Amz-Security-Token", valid_602341
  var valid_602342 = header.getOrDefault("X-Amz-Algorithm")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "X-Amz-Algorithm", valid_602342
  var valid_602343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602343 = validateParameter(valid_602343, JString, required = false,
                                 default = nil)
  if valid_602343 != nil:
    section.add "X-Amz-SignedHeaders", valid_602343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602345: Call_GetApprovalRuleTemplate_602333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified approval rule template.
  ## 
  let valid = call_602345.validator(path, query, header, formData, body)
  let scheme = call_602345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602345.url(scheme.get, call_602345.host, call_602345.base,
                         call_602345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602345, url, valid)

proc call*(call_602346: Call_GetApprovalRuleTemplate_602333; body: JsonNode): Recallable =
  ## getApprovalRuleTemplate
  ## Returns information about a specified approval rule template.
  ##   body: JObject (required)
  var body_602347 = newJObject()
  if body != nil:
    body_602347 = body
  result = call_602346.call(nil, nil, nil, nil, body_602347)

var getApprovalRuleTemplate* = Call_GetApprovalRuleTemplate_602333(
    name: "getApprovalRuleTemplate", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetApprovalRuleTemplate",
    validator: validate_GetApprovalRuleTemplate_602334, base: "/",
    url: url_GetApprovalRuleTemplate_602335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlob_602348 = ref object of OpenApiRestCall_601389
proc url_GetBlob_602350(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBlob_602349(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the base-64 encoded content of an individual blob in a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602351 = header.getOrDefault("X-Amz-Target")
  valid_602351 = validateParameter(valid_602351, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetBlob"))
  if valid_602351 != nil:
    section.add "X-Amz-Target", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Signature")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Signature", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-Content-Sha256", valid_602353
  var valid_602354 = header.getOrDefault("X-Amz-Date")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-Date", valid_602354
  var valid_602355 = header.getOrDefault("X-Amz-Credential")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Credential", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-Security-Token")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Security-Token", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-Algorithm")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Algorithm", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-SignedHeaders", valid_602358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602360: Call_GetBlob_602348; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the base-64 encoded content of an individual blob in a repository.
  ## 
  let valid = call_602360.validator(path, query, header, formData, body)
  let scheme = call_602360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602360.url(scheme.get, call_602360.host, call_602360.base,
                         call_602360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602360, url, valid)

proc call*(call_602361: Call_GetBlob_602348; body: JsonNode): Recallable =
  ## getBlob
  ## Returns the base-64 encoded content of an individual blob in a repository.
  ##   body: JObject (required)
  var body_602362 = newJObject()
  if body != nil:
    body_602362 = body
  result = call_602361.call(nil, nil, nil, nil, body_602362)

var getBlob* = Call_GetBlob_602348(name: "getBlob", meth: HttpMethod.HttpPost,
                                host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetBlob",
                                validator: validate_GetBlob_602349, base: "/",
                                url: url_GetBlob_602350,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBranch_602363 = ref object of OpenApiRestCall_601389
proc url_GetBranch_602365(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBranch_602364(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602366 = header.getOrDefault("X-Amz-Target")
  valid_602366 = validateParameter(valid_602366, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetBranch"))
  if valid_602366 != nil:
    section.add "X-Amz-Target", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Signature")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Signature", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Content-Sha256", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Date")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Date", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-Credential")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-Credential", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-Security-Token")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Security-Token", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-Algorithm")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Algorithm", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-SignedHeaders", valid_602373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602375: Call_GetBranch_602363; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a repository branch, including its name and the last commit ID.
  ## 
  let valid = call_602375.validator(path, query, header, formData, body)
  let scheme = call_602375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602375.url(scheme.get, call_602375.host, call_602375.base,
                         call_602375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602375, url, valid)

proc call*(call_602376: Call_GetBranch_602363; body: JsonNode): Recallable =
  ## getBranch
  ## Returns information about a repository branch, including its name and the last commit ID.
  ##   body: JObject (required)
  var body_602377 = newJObject()
  if body != nil:
    body_602377 = body
  result = call_602376.call(nil, nil, nil, nil, body_602377)

var getBranch* = Call_GetBranch_602363(name: "getBranch", meth: HttpMethod.HttpPost,
                                    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetBranch",
                                    validator: validate_GetBranch_602364,
                                    base: "/", url: url_GetBranch_602365,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComment_602378 = ref object of OpenApiRestCall_601389
proc url_GetComment_602380(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComment_602379(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602381 = header.getOrDefault("X-Amz-Target")
  valid_602381 = validateParameter(valid_602381, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetComment"))
  if valid_602381 != nil:
    section.add "X-Amz-Target", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-Signature")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Signature", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Content-Sha256", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Date")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Date", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-Credential")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-Credential", valid_602385
  var valid_602386 = header.getOrDefault("X-Amz-Security-Token")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-Security-Token", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-Algorithm")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-Algorithm", valid_602387
  var valid_602388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-SignedHeaders", valid_602388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602390: Call_GetComment_602378; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the content of a comment made on a change, file, or commit in a repository.
  ## 
  let valid = call_602390.validator(path, query, header, formData, body)
  let scheme = call_602390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602390.url(scheme.get, call_602390.host, call_602390.base,
                         call_602390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602390, url, valid)

proc call*(call_602391: Call_GetComment_602378; body: JsonNode): Recallable =
  ## getComment
  ## Returns the content of a comment made on a change, file, or commit in a repository.
  ##   body: JObject (required)
  var body_602392 = newJObject()
  if body != nil:
    body_602392 = body
  result = call_602391.call(nil, nil, nil, nil, body_602392)

var getComment* = Call_GetComment_602378(name: "getComment",
                                      meth: HttpMethod.HttpPost,
                                      host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetComment",
                                      validator: validate_GetComment_602379,
                                      base: "/", url: url_GetComment_602380,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommentsForComparedCommit_602393 = ref object of OpenApiRestCall_601389
proc url_GetCommentsForComparedCommit_602395(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCommentsForComparedCommit_602394(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about comments made on the comparison between two commits.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_602396 = query.getOrDefault("nextToken")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "nextToken", valid_602396
  var valid_602397 = query.getOrDefault("maxResults")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "maxResults", valid_602397
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602398 = header.getOrDefault("X-Amz-Target")
  valid_602398 = validateParameter(valid_602398, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommentsForComparedCommit"))
  if valid_602398 != nil:
    section.add "X-Amz-Target", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Signature")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Signature", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Content-Sha256", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-Date")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Date", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Credential")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Credential", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-Security-Token")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Security-Token", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-Algorithm")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-Algorithm", valid_602404
  var valid_602405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-SignedHeaders", valid_602405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602407: Call_GetCommentsForComparedCommit_602393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about comments made on the comparison between two commits.
  ## 
  let valid = call_602407.validator(path, query, header, formData, body)
  let scheme = call_602407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602407.url(scheme.get, call_602407.host, call_602407.base,
                         call_602407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602407, url, valid)

proc call*(call_602408: Call_GetCommentsForComparedCommit_602393; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getCommentsForComparedCommit
  ## Returns information about comments made on the comparison between two commits.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602409 = newJObject()
  var body_602410 = newJObject()
  add(query_602409, "nextToken", newJString(nextToken))
  if body != nil:
    body_602410 = body
  add(query_602409, "maxResults", newJString(maxResults))
  result = call_602408.call(nil, query_602409, nil, nil, body_602410)

var getCommentsForComparedCommit* = Call_GetCommentsForComparedCommit_602393(
    name: "getCommentsForComparedCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetCommentsForComparedCommit",
    validator: validate_GetCommentsForComparedCommit_602394, base: "/",
    url: url_GetCommentsForComparedCommit_602395,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommentsForPullRequest_602411 = ref object of OpenApiRestCall_601389
proc url_GetCommentsForPullRequest_602413(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCommentsForPullRequest_602412(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns comments made on a pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_602414 = query.getOrDefault("nextToken")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "nextToken", valid_602414
  var valid_602415 = query.getOrDefault("maxResults")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "maxResults", valid_602415
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602416 = header.getOrDefault("X-Amz-Target")
  valid_602416 = validateParameter(valid_602416, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommentsForPullRequest"))
  if valid_602416 != nil:
    section.add "X-Amz-Target", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Signature")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Signature", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Content-Sha256", valid_602418
  var valid_602419 = header.getOrDefault("X-Amz-Date")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "X-Amz-Date", valid_602419
  var valid_602420 = header.getOrDefault("X-Amz-Credential")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-Credential", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-Security-Token")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-Security-Token", valid_602421
  var valid_602422 = header.getOrDefault("X-Amz-Algorithm")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "X-Amz-Algorithm", valid_602422
  var valid_602423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = nil)
  if valid_602423 != nil:
    section.add "X-Amz-SignedHeaders", valid_602423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602425: Call_GetCommentsForPullRequest_602411; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns comments made on a pull request.
  ## 
  let valid = call_602425.validator(path, query, header, formData, body)
  let scheme = call_602425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602425.url(scheme.get, call_602425.host, call_602425.base,
                         call_602425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602425, url, valid)

proc call*(call_602426: Call_GetCommentsForPullRequest_602411; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getCommentsForPullRequest
  ## Returns comments made on a pull request.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602427 = newJObject()
  var body_602428 = newJObject()
  add(query_602427, "nextToken", newJString(nextToken))
  if body != nil:
    body_602428 = body
  add(query_602427, "maxResults", newJString(maxResults))
  result = call_602426.call(nil, query_602427, nil, nil, body_602428)

var getCommentsForPullRequest* = Call_GetCommentsForPullRequest_602411(
    name: "getCommentsForPullRequest", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetCommentsForPullRequest",
    validator: validate_GetCommentsForPullRequest_602412, base: "/",
    url: url_GetCommentsForPullRequest_602413,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommit_602429 = ref object of OpenApiRestCall_601389
proc url_GetCommit_602431(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCommit_602430(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602432 = header.getOrDefault("X-Amz-Target")
  valid_602432 = validateParameter(valid_602432, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetCommit"))
  if valid_602432 != nil:
    section.add "X-Amz-Target", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-Signature")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-Signature", valid_602433
  var valid_602434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "X-Amz-Content-Sha256", valid_602434
  var valid_602435 = header.getOrDefault("X-Amz-Date")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "X-Amz-Date", valid_602435
  var valid_602436 = header.getOrDefault("X-Amz-Credential")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-Credential", valid_602436
  var valid_602437 = header.getOrDefault("X-Amz-Security-Token")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-Security-Token", valid_602437
  var valid_602438 = header.getOrDefault("X-Amz-Algorithm")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-Algorithm", valid_602438
  var valid_602439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-SignedHeaders", valid_602439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602441: Call_GetCommit_602429; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a commit, including commit message and committer information.
  ## 
  let valid = call_602441.validator(path, query, header, formData, body)
  let scheme = call_602441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602441.url(scheme.get, call_602441.host, call_602441.base,
                         call_602441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602441, url, valid)

proc call*(call_602442: Call_GetCommit_602429; body: JsonNode): Recallable =
  ## getCommit
  ## Returns information about a commit, including commit message and committer information.
  ##   body: JObject (required)
  var body_602443 = newJObject()
  if body != nil:
    body_602443 = body
  result = call_602442.call(nil, nil, nil, nil, body_602443)

var getCommit* = Call_GetCommit_602429(name: "getCommit", meth: HttpMethod.HttpPost,
                                    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetCommit",
                                    validator: validate_GetCommit_602430,
                                    base: "/", url: url_GetCommit_602431,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDifferences_602444 = ref object of OpenApiRestCall_601389
proc url_GetDifferences_602446(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDifferences_602445(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID, or other fully qualified reference). Results can be limited to a specified path.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_602447 = query.getOrDefault("MaxResults")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "MaxResults", valid_602447
  var valid_602448 = query.getOrDefault("NextToken")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "NextToken", valid_602448
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602449 = header.getOrDefault("X-Amz-Target")
  valid_602449 = validateParameter(valid_602449, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetDifferences"))
  if valid_602449 != nil:
    section.add "X-Amz-Target", valid_602449
  var valid_602450 = header.getOrDefault("X-Amz-Signature")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "X-Amz-Signature", valid_602450
  var valid_602451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-Content-Sha256", valid_602451
  var valid_602452 = header.getOrDefault("X-Amz-Date")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Date", valid_602452
  var valid_602453 = header.getOrDefault("X-Amz-Credential")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "X-Amz-Credential", valid_602453
  var valid_602454 = header.getOrDefault("X-Amz-Security-Token")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-Security-Token", valid_602454
  var valid_602455 = header.getOrDefault("X-Amz-Algorithm")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Algorithm", valid_602455
  var valid_602456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-SignedHeaders", valid_602456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602458: Call_GetDifferences_602444; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID, or other fully qualified reference). Results can be limited to a specified path.
  ## 
  let valid = call_602458.validator(path, query, header, formData, body)
  let scheme = call_602458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602458.url(scheme.get, call_602458.host, call_602458.base,
                         call_602458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602458, url, valid)

proc call*(call_602459: Call_GetDifferences_602444; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getDifferences
  ## Returns information about the differences in a valid commit specifier (such as a branch, tag, HEAD, commit ID, or other fully qualified reference). Results can be limited to a specified path.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602460 = newJObject()
  var body_602461 = newJObject()
  add(query_602460, "MaxResults", newJString(MaxResults))
  add(query_602460, "NextToken", newJString(NextToken))
  if body != nil:
    body_602461 = body
  result = call_602459.call(nil, query_602460, nil, nil, body_602461)

var getDifferences* = Call_GetDifferences_602444(name: "getDifferences",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetDifferences",
    validator: validate_GetDifferences_602445, base: "/", url: url_GetDifferences_602446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFile_602462 = ref object of OpenApiRestCall_601389
proc url_GetFile_602464(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFile_602463(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602465 = header.getOrDefault("X-Amz-Target")
  valid_602465 = validateParameter(valid_602465, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetFile"))
  if valid_602465 != nil:
    section.add "X-Amz-Target", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-Signature")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-Signature", valid_602466
  var valid_602467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602467 = validateParameter(valid_602467, JString, required = false,
                                 default = nil)
  if valid_602467 != nil:
    section.add "X-Amz-Content-Sha256", valid_602467
  var valid_602468 = header.getOrDefault("X-Amz-Date")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "X-Amz-Date", valid_602468
  var valid_602469 = header.getOrDefault("X-Amz-Credential")
  valid_602469 = validateParameter(valid_602469, JString, required = false,
                                 default = nil)
  if valid_602469 != nil:
    section.add "X-Amz-Credential", valid_602469
  var valid_602470 = header.getOrDefault("X-Amz-Security-Token")
  valid_602470 = validateParameter(valid_602470, JString, required = false,
                                 default = nil)
  if valid_602470 != nil:
    section.add "X-Amz-Security-Token", valid_602470
  var valid_602471 = header.getOrDefault("X-Amz-Algorithm")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-Algorithm", valid_602471
  var valid_602472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "X-Amz-SignedHeaders", valid_602472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602474: Call_GetFile_602462; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the base-64 encoded contents of a specified file and its metadata.
  ## 
  let valid = call_602474.validator(path, query, header, formData, body)
  let scheme = call_602474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602474.url(scheme.get, call_602474.host, call_602474.base,
                         call_602474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602474, url, valid)

proc call*(call_602475: Call_GetFile_602462; body: JsonNode): Recallable =
  ## getFile
  ## Returns the base-64 encoded contents of a specified file and its metadata.
  ##   body: JObject (required)
  var body_602476 = newJObject()
  if body != nil:
    body_602476 = body
  result = call_602475.call(nil, nil, nil, nil, body_602476)

var getFile* = Call_GetFile_602462(name: "getFile", meth: HttpMethod.HttpPost,
                                host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetFile",
                                validator: validate_GetFile_602463, base: "/",
                                url: url_GetFile_602464,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFolder_602477 = ref object of OpenApiRestCall_601389
proc url_GetFolder_602479(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetFolder_602478(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602480 = header.getOrDefault("X-Amz-Target")
  valid_602480 = validateParameter(valid_602480, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetFolder"))
  if valid_602480 != nil:
    section.add "X-Amz-Target", valid_602480
  var valid_602481 = header.getOrDefault("X-Amz-Signature")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "X-Amz-Signature", valid_602481
  var valid_602482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "X-Amz-Content-Sha256", valid_602482
  var valid_602483 = header.getOrDefault("X-Amz-Date")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "X-Amz-Date", valid_602483
  var valid_602484 = header.getOrDefault("X-Amz-Credential")
  valid_602484 = validateParameter(valid_602484, JString, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "X-Amz-Credential", valid_602484
  var valid_602485 = header.getOrDefault("X-Amz-Security-Token")
  valid_602485 = validateParameter(valid_602485, JString, required = false,
                                 default = nil)
  if valid_602485 != nil:
    section.add "X-Amz-Security-Token", valid_602485
  var valid_602486 = header.getOrDefault("X-Amz-Algorithm")
  valid_602486 = validateParameter(valid_602486, JString, required = false,
                                 default = nil)
  if valid_602486 != nil:
    section.add "X-Amz-Algorithm", valid_602486
  var valid_602487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602487 = validateParameter(valid_602487, JString, required = false,
                                 default = nil)
  if valid_602487 != nil:
    section.add "X-Amz-SignedHeaders", valid_602487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602489: Call_GetFolder_602477; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the contents of a specified folder in a repository.
  ## 
  let valid = call_602489.validator(path, query, header, formData, body)
  let scheme = call_602489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602489.url(scheme.get, call_602489.host, call_602489.base,
                         call_602489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602489, url, valid)

proc call*(call_602490: Call_GetFolder_602477; body: JsonNode): Recallable =
  ## getFolder
  ## Returns the contents of a specified folder in a repository.
  ##   body: JObject (required)
  var body_602491 = newJObject()
  if body != nil:
    body_602491 = body
  result = call_602490.call(nil, nil, nil, nil, body_602491)

var getFolder* = Call_GetFolder_602477(name: "getFolder", meth: HttpMethod.HttpPost,
                                    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.GetFolder",
                                    validator: validate_GetFolder_602478,
                                    base: "/", url: url_GetFolder_602479,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeCommit_602492 = ref object of OpenApiRestCall_601389
proc url_GetMergeCommit_602494(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMergeCommit_602493(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602495 = header.getOrDefault("X-Amz-Target")
  valid_602495 = validateParameter(valid_602495, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeCommit"))
  if valid_602495 != nil:
    section.add "X-Amz-Target", valid_602495
  var valid_602496 = header.getOrDefault("X-Amz-Signature")
  valid_602496 = validateParameter(valid_602496, JString, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "X-Amz-Signature", valid_602496
  var valid_602497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-Content-Sha256", valid_602497
  var valid_602498 = header.getOrDefault("X-Amz-Date")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "X-Amz-Date", valid_602498
  var valid_602499 = header.getOrDefault("X-Amz-Credential")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-Credential", valid_602499
  var valid_602500 = header.getOrDefault("X-Amz-Security-Token")
  valid_602500 = validateParameter(valid_602500, JString, required = false,
                                 default = nil)
  if valid_602500 != nil:
    section.add "X-Amz-Security-Token", valid_602500
  var valid_602501 = header.getOrDefault("X-Amz-Algorithm")
  valid_602501 = validateParameter(valid_602501, JString, required = false,
                                 default = nil)
  if valid_602501 != nil:
    section.add "X-Amz-Algorithm", valid_602501
  var valid_602502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602502 = validateParameter(valid_602502, JString, required = false,
                                 default = nil)
  if valid_602502 != nil:
    section.add "X-Amz-SignedHeaders", valid_602502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602504: Call_GetMergeCommit_602492; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specified merge commit.
  ## 
  let valid = call_602504.validator(path, query, header, formData, body)
  let scheme = call_602504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602504.url(scheme.get, call_602504.host, call_602504.base,
                         call_602504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602504, url, valid)

proc call*(call_602505: Call_GetMergeCommit_602492; body: JsonNode): Recallable =
  ## getMergeCommit
  ## Returns information about a specified merge commit.
  ##   body: JObject (required)
  var body_602506 = newJObject()
  if body != nil:
    body_602506 = body
  result = call_602505.call(nil, nil, nil, nil, body_602506)

var getMergeCommit* = Call_GetMergeCommit_602492(name: "getMergeCommit",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeCommit",
    validator: validate_GetMergeCommit_602493, base: "/", url: url_GetMergeCommit_602494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeConflicts_602507 = ref object of OpenApiRestCall_601389
proc url_GetMergeConflicts_602509(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMergeConflicts_602508(path: JsonNode; query: JsonNode;
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
  var valid_602510 = query.getOrDefault("nextToken")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "nextToken", valid_602510
  var valid_602511 = query.getOrDefault("maxConflictFiles")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "maxConflictFiles", valid_602511
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602512 = header.getOrDefault("X-Amz-Target")
  valid_602512 = validateParameter(valid_602512, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeConflicts"))
  if valid_602512 != nil:
    section.add "X-Amz-Target", valid_602512
  var valid_602513 = header.getOrDefault("X-Amz-Signature")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "X-Amz-Signature", valid_602513
  var valid_602514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "X-Amz-Content-Sha256", valid_602514
  var valid_602515 = header.getOrDefault("X-Amz-Date")
  valid_602515 = validateParameter(valid_602515, JString, required = false,
                                 default = nil)
  if valid_602515 != nil:
    section.add "X-Amz-Date", valid_602515
  var valid_602516 = header.getOrDefault("X-Amz-Credential")
  valid_602516 = validateParameter(valid_602516, JString, required = false,
                                 default = nil)
  if valid_602516 != nil:
    section.add "X-Amz-Credential", valid_602516
  var valid_602517 = header.getOrDefault("X-Amz-Security-Token")
  valid_602517 = validateParameter(valid_602517, JString, required = false,
                                 default = nil)
  if valid_602517 != nil:
    section.add "X-Amz-Security-Token", valid_602517
  var valid_602518 = header.getOrDefault("X-Amz-Algorithm")
  valid_602518 = validateParameter(valid_602518, JString, required = false,
                                 default = nil)
  if valid_602518 != nil:
    section.add "X-Amz-Algorithm", valid_602518
  var valid_602519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602519 = validateParameter(valid_602519, JString, required = false,
                                 default = nil)
  if valid_602519 != nil:
    section.add "X-Amz-SignedHeaders", valid_602519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602521: Call_GetMergeConflicts_602507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about merge conflicts between the before and after commit IDs for a pull request in a repository.
  ## 
  let valid = call_602521.validator(path, query, header, formData, body)
  let scheme = call_602521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602521.url(scheme.get, call_602521.host, call_602521.base,
                         call_602521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602521, url, valid)

proc call*(call_602522: Call_GetMergeConflicts_602507; body: JsonNode;
          nextToken: string = ""; maxConflictFiles: string = ""): Recallable =
  ## getMergeConflicts
  ## Returns information about merge conflicts between the before and after commit IDs for a pull request in a repository.
  ##   nextToken: string
  ##            : Pagination token
  ##   maxConflictFiles: string
  ##                   : Pagination limit
  ##   body: JObject (required)
  var query_602523 = newJObject()
  var body_602524 = newJObject()
  add(query_602523, "nextToken", newJString(nextToken))
  add(query_602523, "maxConflictFiles", newJString(maxConflictFiles))
  if body != nil:
    body_602524 = body
  result = call_602522.call(nil, query_602523, nil, nil, body_602524)

var getMergeConflicts* = Call_GetMergeConflicts_602507(name: "getMergeConflicts",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeConflicts",
    validator: validate_GetMergeConflicts_602508, base: "/",
    url: url_GetMergeConflicts_602509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMergeOptions_602525 = ref object of OpenApiRestCall_601389
proc url_GetMergeOptions_602527(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMergeOptions_602526(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns information about the merge options available for merging two specified branches. For details about why a merge option is not available, use GetMergeConflicts or DescribeMergeConflicts.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602528 = header.getOrDefault("X-Amz-Target")
  valid_602528 = validateParameter(valid_602528, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetMergeOptions"))
  if valid_602528 != nil:
    section.add "X-Amz-Target", valid_602528
  var valid_602529 = header.getOrDefault("X-Amz-Signature")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "X-Amz-Signature", valid_602529
  var valid_602530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602530 = validateParameter(valid_602530, JString, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "X-Amz-Content-Sha256", valid_602530
  var valid_602531 = header.getOrDefault("X-Amz-Date")
  valid_602531 = validateParameter(valid_602531, JString, required = false,
                                 default = nil)
  if valid_602531 != nil:
    section.add "X-Amz-Date", valid_602531
  var valid_602532 = header.getOrDefault("X-Amz-Credential")
  valid_602532 = validateParameter(valid_602532, JString, required = false,
                                 default = nil)
  if valid_602532 != nil:
    section.add "X-Amz-Credential", valid_602532
  var valid_602533 = header.getOrDefault("X-Amz-Security-Token")
  valid_602533 = validateParameter(valid_602533, JString, required = false,
                                 default = nil)
  if valid_602533 != nil:
    section.add "X-Amz-Security-Token", valid_602533
  var valid_602534 = header.getOrDefault("X-Amz-Algorithm")
  valid_602534 = validateParameter(valid_602534, JString, required = false,
                                 default = nil)
  if valid_602534 != nil:
    section.add "X-Amz-Algorithm", valid_602534
  var valid_602535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "X-Amz-SignedHeaders", valid_602535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602537: Call_GetMergeOptions_602525; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the merge options available for merging two specified branches. For details about why a merge option is not available, use GetMergeConflicts or DescribeMergeConflicts.
  ## 
  let valid = call_602537.validator(path, query, header, formData, body)
  let scheme = call_602537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602537.url(scheme.get, call_602537.host, call_602537.base,
                         call_602537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602537, url, valid)

proc call*(call_602538: Call_GetMergeOptions_602525; body: JsonNode): Recallable =
  ## getMergeOptions
  ## Returns information about the merge options available for merging two specified branches. For details about why a merge option is not available, use GetMergeConflicts or DescribeMergeConflicts.
  ##   body: JObject (required)
  var body_602539 = newJObject()
  if body != nil:
    body_602539 = body
  result = call_602538.call(nil, nil, nil, nil, body_602539)

var getMergeOptions* = Call_GetMergeOptions_602525(name: "getMergeOptions",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetMergeOptions",
    validator: validate_GetMergeOptions_602526, base: "/", url: url_GetMergeOptions_602527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPullRequest_602540 = ref object of OpenApiRestCall_601389
proc url_GetPullRequest_602542(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPullRequest_602541(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602543 = header.getOrDefault("X-Amz-Target")
  valid_602543 = validateParameter(valid_602543, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetPullRequest"))
  if valid_602543 != nil:
    section.add "X-Amz-Target", valid_602543
  var valid_602544 = header.getOrDefault("X-Amz-Signature")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Signature", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-Content-Sha256", valid_602545
  var valid_602546 = header.getOrDefault("X-Amz-Date")
  valid_602546 = validateParameter(valid_602546, JString, required = false,
                                 default = nil)
  if valid_602546 != nil:
    section.add "X-Amz-Date", valid_602546
  var valid_602547 = header.getOrDefault("X-Amz-Credential")
  valid_602547 = validateParameter(valid_602547, JString, required = false,
                                 default = nil)
  if valid_602547 != nil:
    section.add "X-Amz-Credential", valid_602547
  var valid_602548 = header.getOrDefault("X-Amz-Security-Token")
  valid_602548 = validateParameter(valid_602548, JString, required = false,
                                 default = nil)
  if valid_602548 != nil:
    section.add "X-Amz-Security-Token", valid_602548
  var valid_602549 = header.getOrDefault("X-Amz-Algorithm")
  valid_602549 = validateParameter(valid_602549, JString, required = false,
                                 default = nil)
  if valid_602549 != nil:
    section.add "X-Amz-Algorithm", valid_602549
  var valid_602550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602550 = validateParameter(valid_602550, JString, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "X-Amz-SignedHeaders", valid_602550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602552: Call_GetPullRequest_602540; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a pull request in a specified repository.
  ## 
  let valid = call_602552.validator(path, query, header, formData, body)
  let scheme = call_602552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602552.url(scheme.get, call_602552.host, call_602552.base,
                         call_602552.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602552, url, valid)

proc call*(call_602553: Call_GetPullRequest_602540; body: JsonNode): Recallable =
  ## getPullRequest
  ## Gets information about a pull request in a specified repository.
  ##   body: JObject (required)
  var body_602554 = newJObject()
  if body != nil:
    body_602554 = body
  result = call_602553.call(nil, nil, nil, nil, body_602554)

var getPullRequest* = Call_GetPullRequest_602540(name: "getPullRequest",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetPullRequest",
    validator: validate_GetPullRequest_602541, base: "/", url: url_GetPullRequest_602542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPullRequestApprovalStates_602555 = ref object of OpenApiRestCall_601389
proc url_GetPullRequestApprovalStates_602557(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPullRequestApprovalStates_602556(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the approval states for a specified pull request. Approval states only apply to pull requests that have one or more approval rules applied to them.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602558 = header.getOrDefault("X-Amz-Target")
  valid_602558 = validateParameter(valid_602558, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetPullRequestApprovalStates"))
  if valid_602558 != nil:
    section.add "X-Amz-Target", valid_602558
  var valid_602559 = header.getOrDefault("X-Amz-Signature")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-Signature", valid_602559
  var valid_602560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-Content-Sha256", valid_602560
  var valid_602561 = header.getOrDefault("X-Amz-Date")
  valid_602561 = validateParameter(valid_602561, JString, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "X-Amz-Date", valid_602561
  var valid_602562 = header.getOrDefault("X-Amz-Credential")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "X-Amz-Credential", valid_602562
  var valid_602563 = header.getOrDefault("X-Amz-Security-Token")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "X-Amz-Security-Token", valid_602563
  var valid_602564 = header.getOrDefault("X-Amz-Algorithm")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "X-Amz-Algorithm", valid_602564
  var valid_602565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-SignedHeaders", valid_602565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602567: Call_GetPullRequestApprovalStates_602555; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the approval states for a specified pull request. Approval states only apply to pull requests that have one or more approval rules applied to them.
  ## 
  let valid = call_602567.validator(path, query, header, formData, body)
  let scheme = call_602567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602567.url(scheme.get, call_602567.host, call_602567.base,
                         call_602567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602567, url, valid)

proc call*(call_602568: Call_GetPullRequestApprovalStates_602555; body: JsonNode): Recallable =
  ## getPullRequestApprovalStates
  ## Gets information about the approval states for a specified pull request. Approval states only apply to pull requests that have one or more approval rules applied to them.
  ##   body: JObject (required)
  var body_602569 = newJObject()
  if body != nil:
    body_602569 = body
  result = call_602568.call(nil, nil, nil, nil, body_602569)

var getPullRequestApprovalStates* = Call_GetPullRequestApprovalStates_602555(
    name: "getPullRequestApprovalStates", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetPullRequestApprovalStates",
    validator: validate_GetPullRequestApprovalStates_602556, base: "/",
    url: url_GetPullRequestApprovalStates_602557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPullRequestOverrideState_602570 = ref object of OpenApiRestCall_601389
proc url_GetPullRequestOverrideState_602572(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPullRequestOverrideState_602571(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about whether approval rules have been set aside (overridden) for a pull request, and if so, the Amazon Resource Name (ARN) of the user or identity that overrode the rules and their requirements for the pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602573 = header.getOrDefault("X-Amz-Target")
  valid_602573 = validateParameter(valid_602573, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetPullRequestOverrideState"))
  if valid_602573 != nil:
    section.add "X-Amz-Target", valid_602573
  var valid_602574 = header.getOrDefault("X-Amz-Signature")
  valid_602574 = validateParameter(valid_602574, JString, required = false,
                                 default = nil)
  if valid_602574 != nil:
    section.add "X-Amz-Signature", valid_602574
  var valid_602575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602575 = validateParameter(valid_602575, JString, required = false,
                                 default = nil)
  if valid_602575 != nil:
    section.add "X-Amz-Content-Sha256", valid_602575
  var valid_602576 = header.getOrDefault("X-Amz-Date")
  valid_602576 = validateParameter(valid_602576, JString, required = false,
                                 default = nil)
  if valid_602576 != nil:
    section.add "X-Amz-Date", valid_602576
  var valid_602577 = header.getOrDefault("X-Amz-Credential")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "X-Amz-Credential", valid_602577
  var valid_602578 = header.getOrDefault("X-Amz-Security-Token")
  valid_602578 = validateParameter(valid_602578, JString, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "X-Amz-Security-Token", valid_602578
  var valid_602579 = header.getOrDefault("X-Amz-Algorithm")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "X-Amz-Algorithm", valid_602579
  var valid_602580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-SignedHeaders", valid_602580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602582: Call_GetPullRequestOverrideState_602570; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about whether approval rules have been set aside (overridden) for a pull request, and if so, the Amazon Resource Name (ARN) of the user or identity that overrode the rules and their requirements for the pull request.
  ## 
  let valid = call_602582.validator(path, query, header, formData, body)
  let scheme = call_602582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602582.url(scheme.get, call_602582.host, call_602582.base,
                         call_602582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602582, url, valid)

proc call*(call_602583: Call_GetPullRequestOverrideState_602570; body: JsonNode): Recallable =
  ## getPullRequestOverrideState
  ## Returns information about whether approval rules have been set aside (overridden) for a pull request, and if so, the Amazon Resource Name (ARN) of the user or identity that overrode the rules and their requirements for the pull request.
  ##   body: JObject (required)
  var body_602584 = newJObject()
  if body != nil:
    body_602584 = body
  result = call_602583.call(nil, nil, nil, nil, body_602584)

var getPullRequestOverrideState* = Call_GetPullRequestOverrideState_602570(
    name: "getPullRequestOverrideState", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetPullRequestOverrideState",
    validator: validate_GetPullRequestOverrideState_602571, base: "/",
    url: url_GetPullRequestOverrideState_602572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepository_602585 = ref object of OpenApiRestCall_601389
proc url_GetRepository_602587(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRepository_602586(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602588 = header.getOrDefault("X-Amz-Target")
  valid_602588 = validateParameter(valid_602588, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetRepository"))
  if valid_602588 != nil:
    section.add "X-Amz-Target", valid_602588
  var valid_602589 = header.getOrDefault("X-Amz-Signature")
  valid_602589 = validateParameter(valid_602589, JString, required = false,
                                 default = nil)
  if valid_602589 != nil:
    section.add "X-Amz-Signature", valid_602589
  var valid_602590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602590 = validateParameter(valid_602590, JString, required = false,
                                 default = nil)
  if valid_602590 != nil:
    section.add "X-Amz-Content-Sha256", valid_602590
  var valid_602591 = header.getOrDefault("X-Amz-Date")
  valid_602591 = validateParameter(valid_602591, JString, required = false,
                                 default = nil)
  if valid_602591 != nil:
    section.add "X-Amz-Date", valid_602591
  var valid_602592 = header.getOrDefault("X-Amz-Credential")
  valid_602592 = validateParameter(valid_602592, JString, required = false,
                                 default = nil)
  if valid_602592 != nil:
    section.add "X-Amz-Credential", valid_602592
  var valid_602593 = header.getOrDefault("X-Amz-Security-Token")
  valid_602593 = validateParameter(valid_602593, JString, required = false,
                                 default = nil)
  if valid_602593 != nil:
    section.add "X-Amz-Security-Token", valid_602593
  var valid_602594 = header.getOrDefault("X-Amz-Algorithm")
  valid_602594 = validateParameter(valid_602594, JString, required = false,
                                 default = nil)
  if valid_602594 != nil:
    section.add "X-Amz-Algorithm", valid_602594
  var valid_602595 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602595 = validateParameter(valid_602595, JString, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "X-Amz-SignedHeaders", valid_602595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602597: Call_GetRepository_602585; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ## 
  let valid = call_602597.validator(path, query, header, formData, body)
  let scheme = call_602597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602597.url(scheme.get, call_602597.host, call_602597.base,
                         call_602597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602597, url, valid)

proc call*(call_602598: Call_GetRepository_602585; body: JsonNode): Recallable =
  ## getRepository
  ## <p>Returns information about a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ##   body: JObject (required)
  var body_602599 = newJObject()
  if body != nil:
    body_602599 = body
  result = call_602598.call(nil, nil, nil, nil, body_602599)

var getRepository* = Call_GetRepository_602585(name: "getRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetRepository",
    validator: validate_GetRepository_602586, base: "/", url: url_GetRepository_602587,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepositoryTriggers_602600 = ref object of OpenApiRestCall_601389
proc url_GetRepositoryTriggers_602602(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRepositoryTriggers_602601(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602603 = header.getOrDefault("X-Amz-Target")
  valid_602603 = validateParameter(valid_602603, JString, required = true, default = newJString(
      "CodeCommit_20150413.GetRepositoryTriggers"))
  if valid_602603 != nil:
    section.add "X-Amz-Target", valid_602603
  var valid_602604 = header.getOrDefault("X-Amz-Signature")
  valid_602604 = validateParameter(valid_602604, JString, required = false,
                                 default = nil)
  if valid_602604 != nil:
    section.add "X-Amz-Signature", valid_602604
  var valid_602605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602605 = validateParameter(valid_602605, JString, required = false,
                                 default = nil)
  if valid_602605 != nil:
    section.add "X-Amz-Content-Sha256", valid_602605
  var valid_602606 = header.getOrDefault("X-Amz-Date")
  valid_602606 = validateParameter(valid_602606, JString, required = false,
                                 default = nil)
  if valid_602606 != nil:
    section.add "X-Amz-Date", valid_602606
  var valid_602607 = header.getOrDefault("X-Amz-Credential")
  valid_602607 = validateParameter(valid_602607, JString, required = false,
                                 default = nil)
  if valid_602607 != nil:
    section.add "X-Amz-Credential", valid_602607
  var valid_602608 = header.getOrDefault("X-Amz-Security-Token")
  valid_602608 = validateParameter(valid_602608, JString, required = false,
                                 default = nil)
  if valid_602608 != nil:
    section.add "X-Amz-Security-Token", valid_602608
  var valid_602609 = header.getOrDefault("X-Amz-Algorithm")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "X-Amz-Algorithm", valid_602609
  var valid_602610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602610 = validateParameter(valid_602610, JString, required = false,
                                 default = nil)
  if valid_602610 != nil:
    section.add "X-Amz-SignedHeaders", valid_602610
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602612: Call_GetRepositoryTriggers_602600; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about triggers configured for a repository.
  ## 
  let valid = call_602612.validator(path, query, header, formData, body)
  let scheme = call_602612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602612.url(scheme.get, call_602612.host, call_602612.base,
                         call_602612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602612, url, valid)

proc call*(call_602613: Call_GetRepositoryTriggers_602600; body: JsonNode): Recallable =
  ## getRepositoryTriggers
  ## Gets information about triggers configured for a repository.
  ##   body: JObject (required)
  var body_602614 = newJObject()
  if body != nil:
    body_602614 = body
  result = call_602613.call(nil, nil, nil, nil, body_602614)

var getRepositoryTriggers* = Call_GetRepositoryTriggers_602600(
    name: "getRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.GetRepositoryTriggers",
    validator: validate_GetRepositoryTriggers_602601, base: "/",
    url: url_GetRepositoryTriggers_602602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApprovalRuleTemplates_602615 = ref object of OpenApiRestCall_601389
proc url_ListApprovalRuleTemplates_602617(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApprovalRuleTemplates_602616(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all approval rule templates in the specified AWS Region in your AWS account. If an AWS Region is not specified, the AWS Region where you are signed in is used.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_602618 = query.getOrDefault("nextToken")
  valid_602618 = validateParameter(valid_602618, JString, required = false,
                                 default = nil)
  if valid_602618 != nil:
    section.add "nextToken", valid_602618
  var valid_602619 = query.getOrDefault("maxResults")
  valid_602619 = validateParameter(valid_602619, JString, required = false,
                                 default = nil)
  if valid_602619 != nil:
    section.add "maxResults", valid_602619
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602620 = header.getOrDefault("X-Amz-Target")
  valid_602620 = validateParameter(valid_602620, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListApprovalRuleTemplates"))
  if valid_602620 != nil:
    section.add "X-Amz-Target", valid_602620
  var valid_602621 = header.getOrDefault("X-Amz-Signature")
  valid_602621 = validateParameter(valid_602621, JString, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "X-Amz-Signature", valid_602621
  var valid_602622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602622 = validateParameter(valid_602622, JString, required = false,
                                 default = nil)
  if valid_602622 != nil:
    section.add "X-Amz-Content-Sha256", valid_602622
  var valid_602623 = header.getOrDefault("X-Amz-Date")
  valid_602623 = validateParameter(valid_602623, JString, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "X-Amz-Date", valid_602623
  var valid_602624 = header.getOrDefault("X-Amz-Credential")
  valid_602624 = validateParameter(valid_602624, JString, required = false,
                                 default = nil)
  if valid_602624 != nil:
    section.add "X-Amz-Credential", valid_602624
  var valid_602625 = header.getOrDefault("X-Amz-Security-Token")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "X-Amz-Security-Token", valid_602625
  var valid_602626 = header.getOrDefault("X-Amz-Algorithm")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "X-Amz-Algorithm", valid_602626
  var valid_602627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "X-Amz-SignedHeaders", valid_602627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602629: Call_ListApprovalRuleTemplates_602615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all approval rule templates in the specified AWS Region in your AWS account. If an AWS Region is not specified, the AWS Region where you are signed in is used.
  ## 
  let valid = call_602629.validator(path, query, header, formData, body)
  let scheme = call_602629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602629.url(scheme.get, call_602629.host, call_602629.base,
                         call_602629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602629, url, valid)

proc call*(call_602630: Call_ListApprovalRuleTemplates_602615; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listApprovalRuleTemplates
  ## Lists all approval rule templates in the specified AWS Region in your AWS account. If an AWS Region is not specified, the AWS Region where you are signed in is used.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602631 = newJObject()
  var body_602632 = newJObject()
  add(query_602631, "nextToken", newJString(nextToken))
  if body != nil:
    body_602632 = body
  add(query_602631, "maxResults", newJString(maxResults))
  result = call_602630.call(nil, query_602631, nil, nil, body_602632)

var listApprovalRuleTemplates* = Call_ListApprovalRuleTemplates_602615(
    name: "listApprovalRuleTemplates", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListApprovalRuleTemplates",
    validator: validate_ListApprovalRuleTemplates_602616, base: "/",
    url: url_ListApprovalRuleTemplates_602617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociatedApprovalRuleTemplatesForRepository_602633 = ref object of OpenApiRestCall_601389
proc url_ListAssociatedApprovalRuleTemplatesForRepository_602635(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAssociatedApprovalRuleTemplatesForRepository_602634(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Lists all approval rule templates that are associated with a specified repository.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_602636 = query.getOrDefault("nextToken")
  valid_602636 = validateParameter(valid_602636, JString, required = false,
                                 default = nil)
  if valid_602636 != nil:
    section.add "nextToken", valid_602636
  var valid_602637 = query.getOrDefault("maxResults")
  valid_602637 = validateParameter(valid_602637, JString, required = false,
                                 default = nil)
  if valid_602637 != nil:
    section.add "maxResults", valid_602637
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602638 = header.getOrDefault("X-Amz-Target")
  valid_602638 = validateParameter(valid_602638, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListAssociatedApprovalRuleTemplatesForRepository"))
  if valid_602638 != nil:
    section.add "X-Amz-Target", valid_602638
  var valid_602639 = header.getOrDefault("X-Amz-Signature")
  valid_602639 = validateParameter(valid_602639, JString, required = false,
                                 default = nil)
  if valid_602639 != nil:
    section.add "X-Amz-Signature", valid_602639
  var valid_602640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602640 = validateParameter(valid_602640, JString, required = false,
                                 default = nil)
  if valid_602640 != nil:
    section.add "X-Amz-Content-Sha256", valid_602640
  var valid_602641 = header.getOrDefault("X-Amz-Date")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Date", valid_602641
  var valid_602642 = header.getOrDefault("X-Amz-Credential")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-Credential", valid_602642
  var valid_602643 = header.getOrDefault("X-Amz-Security-Token")
  valid_602643 = validateParameter(valid_602643, JString, required = false,
                                 default = nil)
  if valid_602643 != nil:
    section.add "X-Amz-Security-Token", valid_602643
  var valid_602644 = header.getOrDefault("X-Amz-Algorithm")
  valid_602644 = validateParameter(valid_602644, JString, required = false,
                                 default = nil)
  if valid_602644 != nil:
    section.add "X-Amz-Algorithm", valid_602644
  var valid_602645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-SignedHeaders", valid_602645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602647: Call_ListAssociatedApprovalRuleTemplatesForRepository_602633;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all approval rule templates that are associated with a specified repository.
  ## 
  let valid = call_602647.validator(path, query, header, formData, body)
  let scheme = call_602647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602647.url(scheme.get, call_602647.host, call_602647.base,
                         call_602647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602647, url, valid)

proc call*(call_602648: Call_ListAssociatedApprovalRuleTemplatesForRepository_602633;
          body: JsonNode; nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listAssociatedApprovalRuleTemplatesForRepository
  ## Lists all approval rule templates that are associated with a specified repository.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602649 = newJObject()
  var body_602650 = newJObject()
  add(query_602649, "nextToken", newJString(nextToken))
  if body != nil:
    body_602650 = body
  add(query_602649, "maxResults", newJString(maxResults))
  result = call_602648.call(nil, query_602649, nil, nil, body_602650)

var listAssociatedApprovalRuleTemplatesForRepository* = Call_ListAssociatedApprovalRuleTemplatesForRepository_602633(
    name: "listAssociatedApprovalRuleTemplatesForRepository",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.ListAssociatedApprovalRuleTemplatesForRepository",
    validator: validate_ListAssociatedApprovalRuleTemplatesForRepository_602634,
    base: "/", url: url_ListAssociatedApprovalRuleTemplatesForRepository_602635,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBranches_602651 = ref object of OpenApiRestCall_601389
proc url_ListBranches_602653(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListBranches_602652(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602654 = query.getOrDefault("nextToken")
  valid_602654 = validateParameter(valid_602654, JString, required = false,
                                 default = nil)
  if valid_602654 != nil:
    section.add "nextToken", valid_602654
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602655 = header.getOrDefault("X-Amz-Target")
  valid_602655 = validateParameter(valid_602655, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListBranches"))
  if valid_602655 != nil:
    section.add "X-Amz-Target", valid_602655
  var valid_602656 = header.getOrDefault("X-Amz-Signature")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "X-Amz-Signature", valid_602656
  var valid_602657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "X-Amz-Content-Sha256", valid_602657
  var valid_602658 = header.getOrDefault("X-Amz-Date")
  valid_602658 = validateParameter(valid_602658, JString, required = false,
                                 default = nil)
  if valid_602658 != nil:
    section.add "X-Amz-Date", valid_602658
  var valid_602659 = header.getOrDefault("X-Amz-Credential")
  valid_602659 = validateParameter(valid_602659, JString, required = false,
                                 default = nil)
  if valid_602659 != nil:
    section.add "X-Amz-Credential", valid_602659
  var valid_602660 = header.getOrDefault("X-Amz-Security-Token")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "X-Amz-Security-Token", valid_602660
  var valid_602661 = header.getOrDefault("X-Amz-Algorithm")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "X-Amz-Algorithm", valid_602661
  var valid_602662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "X-Amz-SignedHeaders", valid_602662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602664: Call_ListBranches_602651; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more branches in a repository.
  ## 
  let valid = call_602664.validator(path, query, header, formData, body)
  let scheme = call_602664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602664.url(scheme.get, call_602664.host, call_602664.base,
                         call_602664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602664, url, valid)

proc call*(call_602665: Call_ListBranches_602651; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listBranches
  ## Gets information about one or more branches in a repository.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602666 = newJObject()
  var body_602667 = newJObject()
  add(query_602666, "nextToken", newJString(nextToken))
  if body != nil:
    body_602667 = body
  result = call_602665.call(nil, query_602666, nil, nil, body_602667)

var listBranches* = Call_ListBranches_602651(name: "listBranches",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListBranches",
    validator: validate_ListBranches_602652, base: "/", url: url_ListBranches_602653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPullRequests_602668 = ref object of OpenApiRestCall_601389
proc url_ListPullRequests_602670(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPullRequests_602669(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns a list of pull requests for a specified repository. The return list can be refined by pull request status or pull request author ARN.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_602671 = query.getOrDefault("nextToken")
  valid_602671 = validateParameter(valid_602671, JString, required = false,
                                 default = nil)
  if valid_602671 != nil:
    section.add "nextToken", valid_602671
  var valid_602672 = query.getOrDefault("maxResults")
  valid_602672 = validateParameter(valid_602672, JString, required = false,
                                 default = nil)
  if valid_602672 != nil:
    section.add "maxResults", valid_602672
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602673 = header.getOrDefault("X-Amz-Target")
  valid_602673 = validateParameter(valid_602673, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListPullRequests"))
  if valid_602673 != nil:
    section.add "X-Amz-Target", valid_602673
  var valid_602674 = header.getOrDefault("X-Amz-Signature")
  valid_602674 = validateParameter(valid_602674, JString, required = false,
                                 default = nil)
  if valid_602674 != nil:
    section.add "X-Amz-Signature", valid_602674
  var valid_602675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "X-Amz-Content-Sha256", valid_602675
  var valid_602676 = header.getOrDefault("X-Amz-Date")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "X-Amz-Date", valid_602676
  var valid_602677 = header.getOrDefault("X-Amz-Credential")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-Credential", valid_602677
  var valid_602678 = header.getOrDefault("X-Amz-Security-Token")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "X-Amz-Security-Token", valid_602678
  var valid_602679 = header.getOrDefault("X-Amz-Algorithm")
  valid_602679 = validateParameter(valid_602679, JString, required = false,
                                 default = nil)
  if valid_602679 != nil:
    section.add "X-Amz-Algorithm", valid_602679
  var valid_602680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602680 = validateParameter(valid_602680, JString, required = false,
                                 default = nil)
  if valid_602680 != nil:
    section.add "X-Amz-SignedHeaders", valid_602680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602682: Call_ListPullRequests_602668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of pull requests for a specified repository. The return list can be refined by pull request status or pull request author ARN.
  ## 
  let valid = call_602682.validator(path, query, header, formData, body)
  let scheme = call_602682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602682.url(scheme.get, call_602682.host, call_602682.base,
                         call_602682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602682, url, valid)

proc call*(call_602683: Call_ListPullRequests_602668; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listPullRequests
  ## Returns a list of pull requests for a specified repository. The return list can be refined by pull request status or pull request author ARN.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602684 = newJObject()
  var body_602685 = newJObject()
  add(query_602684, "nextToken", newJString(nextToken))
  if body != nil:
    body_602685 = body
  add(query_602684, "maxResults", newJString(maxResults))
  result = call_602683.call(nil, query_602684, nil, nil, body_602685)

var listPullRequests* = Call_ListPullRequests_602668(name: "listPullRequests",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListPullRequests",
    validator: validate_ListPullRequests_602669, base: "/",
    url: url_ListPullRequests_602670, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRepositories_602686 = ref object of OpenApiRestCall_601389
proc url_ListRepositories_602688(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRepositories_602687(path: JsonNode; query: JsonNode;
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
  var valid_602689 = query.getOrDefault("nextToken")
  valid_602689 = validateParameter(valid_602689, JString, required = false,
                                 default = nil)
  if valid_602689 != nil:
    section.add "nextToken", valid_602689
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602690 = header.getOrDefault("X-Amz-Target")
  valid_602690 = validateParameter(valid_602690, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListRepositories"))
  if valid_602690 != nil:
    section.add "X-Amz-Target", valid_602690
  var valid_602691 = header.getOrDefault("X-Amz-Signature")
  valid_602691 = validateParameter(valid_602691, JString, required = false,
                                 default = nil)
  if valid_602691 != nil:
    section.add "X-Amz-Signature", valid_602691
  var valid_602692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602692 = validateParameter(valid_602692, JString, required = false,
                                 default = nil)
  if valid_602692 != nil:
    section.add "X-Amz-Content-Sha256", valid_602692
  var valid_602693 = header.getOrDefault("X-Amz-Date")
  valid_602693 = validateParameter(valid_602693, JString, required = false,
                                 default = nil)
  if valid_602693 != nil:
    section.add "X-Amz-Date", valid_602693
  var valid_602694 = header.getOrDefault("X-Amz-Credential")
  valid_602694 = validateParameter(valid_602694, JString, required = false,
                                 default = nil)
  if valid_602694 != nil:
    section.add "X-Amz-Credential", valid_602694
  var valid_602695 = header.getOrDefault("X-Amz-Security-Token")
  valid_602695 = validateParameter(valid_602695, JString, required = false,
                                 default = nil)
  if valid_602695 != nil:
    section.add "X-Amz-Security-Token", valid_602695
  var valid_602696 = header.getOrDefault("X-Amz-Algorithm")
  valid_602696 = validateParameter(valid_602696, JString, required = false,
                                 default = nil)
  if valid_602696 != nil:
    section.add "X-Amz-Algorithm", valid_602696
  var valid_602697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602697 = validateParameter(valid_602697, JString, required = false,
                                 default = nil)
  if valid_602697 != nil:
    section.add "X-Amz-SignedHeaders", valid_602697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602699: Call_ListRepositories_602686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more repositories.
  ## 
  let valid = call_602699.validator(path, query, header, formData, body)
  let scheme = call_602699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602699.url(scheme.get, call_602699.host, call_602699.base,
                         call_602699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602699, url, valid)

proc call*(call_602700: Call_ListRepositories_602686; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listRepositories
  ## Gets information about one or more repositories.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_602701 = newJObject()
  var body_602702 = newJObject()
  add(query_602701, "nextToken", newJString(nextToken))
  if body != nil:
    body_602702 = body
  result = call_602700.call(nil, query_602701, nil, nil, body_602702)

var listRepositories* = Call_ListRepositories_602686(name: "listRepositories",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListRepositories",
    validator: validate_ListRepositories_602687, base: "/",
    url: url_ListRepositories_602688, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRepositoriesForApprovalRuleTemplate_602703 = ref object of OpenApiRestCall_601389
proc url_ListRepositoriesForApprovalRuleTemplate_602705(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRepositoriesForApprovalRuleTemplate_602704(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all repositories associated with the specified approval rule template.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_602706 = query.getOrDefault("nextToken")
  valid_602706 = validateParameter(valid_602706, JString, required = false,
                                 default = nil)
  if valid_602706 != nil:
    section.add "nextToken", valid_602706
  var valid_602707 = query.getOrDefault("maxResults")
  valid_602707 = validateParameter(valid_602707, JString, required = false,
                                 default = nil)
  if valid_602707 != nil:
    section.add "maxResults", valid_602707
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602708 = header.getOrDefault("X-Amz-Target")
  valid_602708 = validateParameter(valid_602708, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListRepositoriesForApprovalRuleTemplate"))
  if valid_602708 != nil:
    section.add "X-Amz-Target", valid_602708
  var valid_602709 = header.getOrDefault("X-Amz-Signature")
  valid_602709 = validateParameter(valid_602709, JString, required = false,
                                 default = nil)
  if valid_602709 != nil:
    section.add "X-Amz-Signature", valid_602709
  var valid_602710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "X-Amz-Content-Sha256", valid_602710
  var valid_602711 = header.getOrDefault("X-Amz-Date")
  valid_602711 = validateParameter(valid_602711, JString, required = false,
                                 default = nil)
  if valid_602711 != nil:
    section.add "X-Amz-Date", valid_602711
  var valid_602712 = header.getOrDefault("X-Amz-Credential")
  valid_602712 = validateParameter(valid_602712, JString, required = false,
                                 default = nil)
  if valid_602712 != nil:
    section.add "X-Amz-Credential", valid_602712
  var valid_602713 = header.getOrDefault("X-Amz-Security-Token")
  valid_602713 = validateParameter(valid_602713, JString, required = false,
                                 default = nil)
  if valid_602713 != nil:
    section.add "X-Amz-Security-Token", valid_602713
  var valid_602714 = header.getOrDefault("X-Amz-Algorithm")
  valid_602714 = validateParameter(valid_602714, JString, required = false,
                                 default = nil)
  if valid_602714 != nil:
    section.add "X-Amz-Algorithm", valid_602714
  var valid_602715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602715 = validateParameter(valid_602715, JString, required = false,
                                 default = nil)
  if valid_602715 != nil:
    section.add "X-Amz-SignedHeaders", valid_602715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602717: Call_ListRepositoriesForApprovalRuleTemplate_602703;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all repositories associated with the specified approval rule template.
  ## 
  let valid = call_602717.validator(path, query, header, formData, body)
  let scheme = call_602717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602717.url(scheme.get, call_602717.host, call_602717.base,
                         call_602717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602717, url, valid)

proc call*(call_602718: Call_ListRepositoriesForApprovalRuleTemplate_602703;
          body: JsonNode; nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listRepositoriesForApprovalRuleTemplate
  ## Lists all repositories associated with the specified approval rule template.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_602719 = newJObject()
  var body_602720 = newJObject()
  add(query_602719, "nextToken", newJString(nextToken))
  if body != nil:
    body_602720 = body
  add(query_602719, "maxResults", newJString(maxResults))
  result = call_602718.call(nil, query_602719, nil, nil, body_602720)

var listRepositoriesForApprovalRuleTemplate* = Call_ListRepositoriesForApprovalRuleTemplate_602703(
    name: "listRepositoriesForApprovalRuleTemplate", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.ListRepositoriesForApprovalRuleTemplate",
    validator: validate_ListRepositoriesForApprovalRuleTemplate_602704, base: "/",
    url: url_ListRepositoriesForApprovalRuleTemplate_602705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602721 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602723(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_602722(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the<i> AWS CodeCommit User Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602724 = header.getOrDefault("X-Amz-Target")
  valid_602724 = validateParameter(valid_602724, JString, required = true, default = newJString(
      "CodeCommit_20150413.ListTagsForResource"))
  if valid_602724 != nil:
    section.add "X-Amz-Target", valid_602724
  var valid_602725 = header.getOrDefault("X-Amz-Signature")
  valid_602725 = validateParameter(valid_602725, JString, required = false,
                                 default = nil)
  if valid_602725 != nil:
    section.add "X-Amz-Signature", valid_602725
  var valid_602726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602726 = validateParameter(valid_602726, JString, required = false,
                                 default = nil)
  if valid_602726 != nil:
    section.add "X-Amz-Content-Sha256", valid_602726
  var valid_602727 = header.getOrDefault("X-Amz-Date")
  valid_602727 = validateParameter(valid_602727, JString, required = false,
                                 default = nil)
  if valid_602727 != nil:
    section.add "X-Amz-Date", valid_602727
  var valid_602728 = header.getOrDefault("X-Amz-Credential")
  valid_602728 = validateParameter(valid_602728, JString, required = false,
                                 default = nil)
  if valid_602728 != nil:
    section.add "X-Amz-Credential", valid_602728
  var valid_602729 = header.getOrDefault("X-Amz-Security-Token")
  valid_602729 = validateParameter(valid_602729, JString, required = false,
                                 default = nil)
  if valid_602729 != nil:
    section.add "X-Amz-Security-Token", valid_602729
  var valid_602730 = header.getOrDefault("X-Amz-Algorithm")
  valid_602730 = validateParameter(valid_602730, JString, required = false,
                                 default = nil)
  if valid_602730 != nil:
    section.add "X-Amz-Algorithm", valid_602730
  var valid_602731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602731 = validateParameter(valid_602731, JString, required = false,
                                 default = nil)
  if valid_602731 != nil:
    section.add "X-Amz-SignedHeaders", valid_602731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602733: Call_ListTagsForResource_602721; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the<i> AWS CodeCommit User Guide</i>.
  ## 
  let valid = call_602733.validator(path, query, header, formData, body)
  let scheme = call_602733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602733.url(scheme.get, call_602733.host, call_602733.base,
                         call_602733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602733, url, valid)

proc call*(call_602734: Call_ListTagsForResource_602721; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Gets information about AWS tags for a specified Amazon Resource Name (ARN) in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the<i> AWS CodeCommit User Guide</i>.
  ##   body: JObject (required)
  var body_602735 = newJObject()
  if body != nil:
    body_602735 = body
  result = call_602734.call(nil, nil, nil, nil, body_602735)

var listTagsForResource* = Call_ListTagsForResource_602721(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.ListTagsForResource",
    validator: validate_ListTagsForResource_602722, base: "/",
    url: url_ListTagsForResource_602723, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesByFastForward_602736 = ref object of OpenApiRestCall_601389
proc url_MergeBranchesByFastForward_602738(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergeBranchesByFastForward_602737(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602739 = header.getOrDefault("X-Amz-Target")
  valid_602739 = validateParameter(valid_602739, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesByFastForward"))
  if valid_602739 != nil:
    section.add "X-Amz-Target", valid_602739
  var valid_602740 = header.getOrDefault("X-Amz-Signature")
  valid_602740 = validateParameter(valid_602740, JString, required = false,
                                 default = nil)
  if valid_602740 != nil:
    section.add "X-Amz-Signature", valid_602740
  var valid_602741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602741 = validateParameter(valid_602741, JString, required = false,
                                 default = nil)
  if valid_602741 != nil:
    section.add "X-Amz-Content-Sha256", valid_602741
  var valid_602742 = header.getOrDefault("X-Amz-Date")
  valid_602742 = validateParameter(valid_602742, JString, required = false,
                                 default = nil)
  if valid_602742 != nil:
    section.add "X-Amz-Date", valid_602742
  var valid_602743 = header.getOrDefault("X-Amz-Credential")
  valid_602743 = validateParameter(valid_602743, JString, required = false,
                                 default = nil)
  if valid_602743 != nil:
    section.add "X-Amz-Credential", valid_602743
  var valid_602744 = header.getOrDefault("X-Amz-Security-Token")
  valid_602744 = validateParameter(valid_602744, JString, required = false,
                                 default = nil)
  if valid_602744 != nil:
    section.add "X-Amz-Security-Token", valid_602744
  var valid_602745 = header.getOrDefault("X-Amz-Algorithm")
  valid_602745 = validateParameter(valid_602745, JString, required = false,
                                 default = nil)
  if valid_602745 != nil:
    section.add "X-Amz-Algorithm", valid_602745
  var valid_602746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602746 = validateParameter(valid_602746, JString, required = false,
                                 default = nil)
  if valid_602746 != nil:
    section.add "X-Amz-SignedHeaders", valid_602746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602748: Call_MergeBranchesByFastForward_602736; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Merges two branches using the fast-forward merge strategy.
  ## 
  let valid = call_602748.validator(path, query, header, formData, body)
  let scheme = call_602748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602748.url(scheme.get, call_602748.host, call_602748.base,
                         call_602748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602748, url, valid)

proc call*(call_602749: Call_MergeBranchesByFastForward_602736; body: JsonNode): Recallable =
  ## mergeBranchesByFastForward
  ## Merges two branches using the fast-forward merge strategy.
  ##   body: JObject (required)
  var body_602750 = newJObject()
  if body != nil:
    body_602750 = body
  result = call_602749.call(nil, nil, nil, nil, body_602750)

var mergeBranchesByFastForward* = Call_MergeBranchesByFastForward_602736(
    name: "mergeBranchesByFastForward", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesByFastForward",
    validator: validate_MergeBranchesByFastForward_602737, base: "/",
    url: url_MergeBranchesByFastForward_602738,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesBySquash_602751 = ref object of OpenApiRestCall_601389
proc url_MergeBranchesBySquash_602753(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergeBranchesBySquash_602752(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602754 = header.getOrDefault("X-Amz-Target")
  valid_602754 = validateParameter(valid_602754, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesBySquash"))
  if valid_602754 != nil:
    section.add "X-Amz-Target", valid_602754
  var valid_602755 = header.getOrDefault("X-Amz-Signature")
  valid_602755 = validateParameter(valid_602755, JString, required = false,
                                 default = nil)
  if valid_602755 != nil:
    section.add "X-Amz-Signature", valid_602755
  var valid_602756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602756 = validateParameter(valid_602756, JString, required = false,
                                 default = nil)
  if valid_602756 != nil:
    section.add "X-Amz-Content-Sha256", valid_602756
  var valid_602757 = header.getOrDefault("X-Amz-Date")
  valid_602757 = validateParameter(valid_602757, JString, required = false,
                                 default = nil)
  if valid_602757 != nil:
    section.add "X-Amz-Date", valid_602757
  var valid_602758 = header.getOrDefault("X-Amz-Credential")
  valid_602758 = validateParameter(valid_602758, JString, required = false,
                                 default = nil)
  if valid_602758 != nil:
    section.add "X-Amz-Credential", valid_602758
  var valid_602759 = header.getOrDefault("X-Amz-Security-Token")
  valid_602759 = validateParameter(valid_602759, JString, required = false,
                                 default = nil)
  if valid_602759 != nil:
    section.add "X-Amz-Security-Token", valid_602759
  var valid_602760 = header.getOrDefault("X-Amz-Algorithm")
  valid_602760 = validateParameter(valid_602760, JString, required = false,
                                 default = nil)
  if valid_602760 != nil:
    section.add "X-Amz-Algorithm", valid_602760
  var valid_602761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602761 = validateParameter(valid_602761, JString, required = false,
                                 default = nil)
  if valid_602761 != nil:
    section.add "X-Amz-SignedHeaders", valid_602761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602763: Call_MergeBranchesBySquash_602751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Merges two branches using the squash merge strategy.
  ## 
  let valid = call_602763.validator(path, query, header, formData, body)
  let scheme = call_602763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602763.url(scheme.get, call_602763.host, call_602763.base,
                         call_602763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602763, url, valid)

proc call*(call_602764: Call_MergeBranchesBySquash_602751; body: JsonNode): Recallable =
  ## mergeBranchesBySquash
  ## Merges two branches using the squash merge strategy.
  ##   body: JObject (required)
  var body_602765 = newJObject()
  if body != nil:
    body_602765 = body
  result = call_602764.call(nil, nil, nil, nil, body_602765)

var mergeBranchesBySquash* = Call_MergeBranchesBySquash_602751(
    name: "mergeBranchesBySquash", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesBySquash",
    validator: validate_MergeBranchesBySquash_602752, base: "/",
    url: url_MergeBranchesBySquash_602753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergeBranchesByThreeWay_602766 = ref object of OpenApiRestCall_601389
proc url_MergeBranchesByThreeWay_602768(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergeBranchesByThreeWay_602767(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602769 = header.getOrDefault("X-Amz-Target")
  valid_602769 = validateParameter(valid_602769, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergeBranchesByThreeWay"))
  if valid_602769 != nil:
    section.add "X-Amz-Target", valid_602769
  var valid_602770 = header.getOrDefault("X-Amz-Signature")
  valid_602770 = validateParameter(valid_602770, JString, required = false,
                                 default = nil)
  if valid_602770 != nil:
    section.add "X-Amz-Signature", valid_602770
  var valid_602771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602771 = validateParameter(valid_602771, JString, required = false,
                                 default = nil)
  if valid_602771 != nil:
    section.add "X-Amz-Content-Sha256", valid_602771
  var valid_602772 = header.getOrDefault("X-Amz-Date")
  valid_602772 = validateParameter(valid_602772, JString, required = false,
                                 default = nil)
  if valid_602772 != nil:
    section.add "X-Amz-Date", valid_602772
  var valid_602773 = header.getOrDefault("X-Amz-Credential")
  valid_602773 = validateParameter(valid_602773, JString, required = false,
                                 default = nil)
  if valid_602773 != nil:
    section.add "X-Amz-Credential", valid_602773
  var valid_602774 = header.getOrDefault("X-Amz-Security-Token")
  valid_602774 = validateParameter(valid_602774, JString, required = false,
                                 default = nil)
  if valid_602774 != nil:
    section.add "X-Amz-Security-Token", valid_602774
  var valid_602775 = header.getOrDefault("X-Amz-Algorithm")
  valid_602775 = validateParameter(valid_602775, JString, required = false,
                                 default = nil)
  if valid_602775 != nil:
    section.add "X-Amz-Algorithm", valid_602775
  var valid_602776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602776 = validateParameter(valid_602776, JString, required = false,
                                 default = nil)
  if valid_602776 != nil:
    section.add "X-Amz-SignedHeaders", valid_602776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602778: Call_MergeBranchesByThreeWay_602766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Merges two specified branches using the three-way merge strategy.
  ## 
  let valid = call_602778.validator(path, query, header, formData, body)
  let scheme = call_602778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602778.url(scheme.get, call_602778.host, call_602778.base,
                         call_602778.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602778, url, valid)

proc call*(call_602779: Call_MergeBranchesByThreeWay_602766; body: JsonNode): Recallable =
  ## mergeBranchesByThreeWay
  ## Merges two specified branches using the three-way merge strategy.
  ##   body: JObject (required)
  var body_602780 = newJObject()
  if body != nil:
    body_602780 = body
  result = call_602779.call(nil, nil, nil, nil, body_602780)

var mergeBranchesByThreeWay* = Call_MergeBranchesByThreeWay_602766(
    name: "mergeBranchesByThreeWay", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergeBranchesByThreeWay",
    validator: validate_MergeBranchesByThreeWay_602767, base: "/",
    url: url_MergeBranchesByThreeWay_602768, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestByFastForward_602781 = ref object of OpenApiRestCall_601389
proc url_MergePullRequestByFastForward_602783(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergePullRequestByFastForward_602782(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602784 = header.getOrDefault("X-Amz-Target")
  valid_602784 = validateParameter(valid_602784, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestByFastForward"))
  if valid_602784 != nil:
    section.add "X-Amz-Target", valid_602784
  var valid_602785 = header.getOrDefault("X-Amz-Signature")
  valid_602785 = validateParameter(valid_602785, JString, required = false,
                                 default = nil)
  if valid_602785 != nil:
    section.add "X-Amz-Signature", valid_602785
  var valid_602786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602786 = validateParameter(valid_602786, JString, required = false,
                                 default = nil)
  if valid_602786 != nil:
    section.add "X-Amz-Content-Sha256", valid_602786
  var valid_602787 = header.getOrDefault("X-Amz-Date")
  valid_602787 = validateParameter(valid_602787, JString, required = false,
                                 default = nil)
  if valid_602787 != nil:
    section.add "X-Amz-Date", valid_602787
  var valid_602788 = header.getOrDefault("X-Amz-Credential")
  valid_602788 = validateParameter(valid_602788, JString, required = false,
                                 default = nil)
  if valid_602788 != nil:
    section.add "X-Amz-Credential", valid_602788
  var valid_602789 = header.getOrDefault("X-Amz-Security-Token")
  valid_602789 = validateParameter(valid_602789, JString, required = false,
                                 default = nil)
  if valid_602789 != nil:
    section.add "X-Amz-Security-Token", valid_602789
  var valid_602790 = header.getOrDefault("X-Amz-Algorithm")
  valid_602790 = validateParameter(valid_602790, JString, required = false,
                                 default = nil)
  if valid_602790 != nil:
    section.add "X-Amz-Algorithm", valid_602790
  var valid_602791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602791 = validateParameter(valid_602791, JString, required = false,
                                 default = nil)
  if valid_602791 != nil:
    section.add "X-Amz-SignedHeaders", valid_602791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602793: Call_MergePullRequestByFastForward_602781; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the fast-forward merge strategy. If the merge is successful, it closes the pull request.
  ## 
  let valid = call_602793.validator(path, query, header, formData, body)
  let scheme = call_602793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602793.url(scheme.get, call_602793.host, call_602793.base,
                         call_602793.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602793, url, valid)

proc call*(call_602794: Call_MergePullRequestByFastForward_602781; body: JsonNode): Recallable =
  ## mergePullRequestByFastForward
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the fast-forward merge strategy. If the merge is successful, it closes the pull request.
  ##   body: JObject (required)
  var body_602795 = newJObject()
  if body != nil:
    body_602795 = body
  result = call_602794.call(nil, nil, nil, nil, body_602795)

var mergePullRequestByFastForward* = Call_MergePullRequestByFastForward_602781(
    name: "mergePullRequestByFastForward", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestByFastForward",
    validator: validate_MergePullRequestByFastForward_602782, base: "/",
    url: url_MergePullRequestByFastForward_602783,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestBySquash_602796 = ref object of OpenApiRestCall_601389
proc url_MergePullRequestBySquash_602798(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergePullRequestBySquash_602797(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602799 = header.getOrDefault("X-Amz-Target")
  valid_602799 = validateParameter(valid_602799, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestBySquash"))
  if valid_602799 != nil:
    section.add "X-Amz-Target", valid_602799
  var valid_602800 = header.getOrDefault("X-Amz-Signature")
  valid_602800 = validateParameter(valid_602800, JString, required = false,
                                 default = nil)
  if valid_602800 != nil:
    section.add "X-Amz-Signature", valid_602800
  var valid_602801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602801 = validateParameter(valid_602801, JString, required = false,
                                 default = nil)
  if valid_602801 != nil:
    section.add "X-Amz-Content-Sha256", valid_602801
  var valid_602802 = header.getOrDefault("X-Amz-Date")
  valid_602802 = validateParameter(valid_602802, JString, required = false,
                                 default = nil)
  if valid_602802 != nil:
    section.add "X-Amz-Date", valid_602802
  var valid_602803 = header.getOrDefault("X-Amz-Credential")
  valid_602803 = validateParameter(valid_602803, JString, required = false,
                                 default = nil)
  if valid_602803 != nil:
    section.add "X-Amz-Credential", valid_602803
  var valid_602804 = header.getOrDefault("X-Amz-Security-Token")
  valid_602804 = validateParameter(valid_602804, JString, required = false,
                                 default = nil)
  if valid_602804 != nil:
    section.add "X-Amz-Security-Token", valid_602804
  var valid_602805 = header.getOrDefault("X-Amz-Algorithm")
  valid_602805 = validateParameter(valid_602805, JString, required = false,
                                 default = nil)
  if valid_602805 != nil:
    section.add "X-Amz-Algorithm", valid_602805
  var valid_602806 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602806 = validateParameter(valid_602806, JString, required = false,
                                 default = nil)
  if valid_602806 != nil:
    section.add "X-Amz-SignedHeaders", valid_602806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602808: Call_MergePullRequestBySquash_602796; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the squash merge strategy. If the merge is successful, it closes the pull request.
  ## 
  let valid = call_602808.validator(path, query, header, formData, body)
  let scheme = call_602808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602808.url(scheme.get, call_602808.host, call_602808.base,
                         call_602808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602808, url, valid)

proc call*(call_602809: Call_MergePullRequestBySquash_602796; body: JsonNode): Recallable =
  ## mergePullRequestBySquash
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the squash merge strategy. If the merge is successful, it closes the pull request.
  ##   body: JObject (required)
  var body_602810 = newJObject()
  if body != nil:
    body_602810 = body
  result = call_602809.call(nil, nil, nil, nil, body_602810)

var mergePullRequestBySquash* = Call_MergePullRequestBySquash_602796(
    name: "mergePullRequestBySquash", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestBySquash",
    validator: validate_MergePullRequestBySquash_602797, base: "/",
    url: url_MergePullRequestBySquash_602798, schemes: {Scheme.Https, Scheme.Http})
type
  Call_MergePullRequestByThreeWay_602811 = ref object of OpenApiRestCall_601389
proc url_MergePullRequestByThreeWay_602813(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_MergePullRequestByThreeWay_602812(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602814 = header.getOrDefault("X-Amz-Target")
  valid_602814 = validateParameter(valid_602814, JString, required = true, default = newJString(
      "CodeCommit_20150413.MergePullRequestByThreeWay"))
  if valid_602814 != nil:
    section.add "X-Amz-Target", valid_602814
  var valid_602815 = header.getOrDefault("X-Amz-Signature")
  valid_602815 = validateParameter(valid_602815, JString, required = false,
                                 default = nil)
  if valid_602815 != nil:
    section.add "X-Amz-Signature", valid_602815
  var valid_602816 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602816 = validateParameter(valid_602816, JString, required = false,
                                 default = nil)
  if valid_602816 != nil:
    section.add "X-Amz-Content-Sha256", valid_602816
  var valid_602817 = header.getOrDefault("X-Amz-Date")
  valid_602817 = validateParameter(valid_602817, JString, required = false,
                                 default = nil)
  if valid_602817 != nil:
    section.add "X-Amz-Date", valid_602817
  var valid_602818 = header.getOrDefault("X-Amz-Credential")
  valid_602818 = validateParameter(valid_602818, JString, required = false,
                                 default = nil)
  if valid_602818 != nil:
    section.add "X-Amz-Credential", valid_602818
  var valid_602819 = header.getOrDefault("X-Amz-Security-Token")
  valid_602819 = validateParameter(valid_602819, JString, required = false,
                                 default = nil)
  if valid_602819 != nil:
    section.add "X-Amz-Security-Token", valid_602819
  var valid_602820 = header.getOrDefault("X-Amz-Algorithm")
  valid_602820 = validateParameter(valid_602820, JString, required = false,
                                 default = nil)
  if valid_602820 != nil:
    section.add "X-Amz-Algorithm", valid_602820
  var valid_602821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602821 = validateParameter(valid_602821, JString, required = false,
                                 default = nil)
  if valid_602821 != nil:
    section.add "X-Amz-SignedHeaders", valid_602821
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602823: Call_MergePullRequestByThreeWay_602811; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the three-way merge strategy. If the merge is successful, it closes the pull request.
  ## 
  let valid = call_602823.validator(path, query, header, formData, body)
  let scheme = call_602823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602823.url(scheme.get, call_602823.host, call_602823.base,
                         call_602823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602823, url, valid)

proc call*(call_602824: Call_MergePullRequestByThreeWay_602811; body: JsonNode): Recallable =
  ## mergePullRequestByThreeWay
  ## Attempts to merge the source commit of a pull request into the specified destination branch for that pull request at the specified commit using the three-way merge strategy. If the merge is successful, it closes the pull request.
  ##   body: JObject (required)
  var body_602825 = newJObject()
  if body != nil:
    body_602825 = body
  result = call_602824.call(nil, nil, nil, nil, body_602825)

var mergePullRequestByThreeWay* = Call_MergePullRequestByThreeWay_602811(
    name: "mergePullRequestByThreeWay", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.MergePullRequestByThreeWay",
    validator: validate_MergePullRequestByThreeWay_602812, base: "/",
    url: url_MergePullRequestByThreeWay_602813,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_OverridePullRequestApprovalRules_602826 = ref object of OpenApiRestCall_601389
proc url_OverridePullRequestApprovalRules_602828(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_OverridePullRequestApprovalRules_602827(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets aside (overrides) all approval rule requirements for a specified pull request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602829 = header.getOrDefault("X-Amz-Target")
  valid_602829 = validateParameter(valid_602829, JString, required = true, default = newJString(
      "CodeCommit_20150413.OverridePullRequestApprovalRules"))
  if valid_602829 != nil:
    section.add "X-Amz-Target", valid_602829
  var valid_602830 = header.getOrDefault("X-Amz-Signature")
  valid_602830 = validateParameter(valid_602830, JString, required = false,
                                 default = nil)
  if valid_602830 != nil:
    section.add "X-Amz-Signature", valid_602830
  var valid_602831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602831 = validateParameter(valid_602831, JString, required = false,
                                 default = nil)
  if valid_602831 != nil:
    section.add "X-Amz-Content-Sha256", valid_602831
  var valid_602832 = header.getOrDefault("X-Amz-Date")
  valid_602832 = validateParameter(valid_602832, JString, required = false,
                                 default = nil)
  if valid_602832 != nil:
    section.add "X-Amz-Date", valid_602832
  var valid_602833 = header.getOrDefault("X-Amz-Credential")
  valid_602833 = validateParameter(valid_602833, JString, required = false,
                                 default = nil)
  if valid_602833 != nil:
    section.add "X-Amz-Credential", valid_602833
  var valid_602834 = header.getOrDefault("X-Amz-Security-Token")
  valid_602834 = validateParameter(valid_602834, JString, required = false,
                                 default = nil)
  if valid_602834 != nil:
    section.add "X-Amz-Security-Token", valid_602834
  var valid_602835 = header.getOrDefault("X-Amz-Algorithm")
  valid_602835 = validateParameter(valid_602835, JString, required = false,
                                 default = nil)
  if valid_602835 != nil:
    section.add "X-Amz-Algorithm", valid_602835
  var valid_602836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602836 = validateParameter(valid_602836, JString, required = false,
                                 default = nil)
  if valid_602836 != nil:
    section.add "X-Amz-SignedHeaders", valid_602836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602838: Call_OverridePullRequestApprovalRules_602826;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets aside (overrides) all approval rule requirements for a specified pull request.
  ## 
  let valid = call_602838.validator(path, query, header, formData, body)
  let scheme = call_602838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602838.url(scheme.get, call_602838.host, call_602838.base,
                         call_602838.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602838, url, valid)

proc call*(call_602839: Call_OverridePullRequestApprovalRules_602826;
          body: JsonNode): Recallable =
  ## overridePullRequestApprovalRules
  ## Sets aside (overrides) all approval rule requirements for a specified pull request.
  ##   body: JObject (required)
  var body_602840 = newJObject()
  if body != nil:
    body_602840 = body
  result = call_602839.call(nil, nil, nil, nil, body_602840)

var overridePullRequestApprovalRules* = Call_OverridePullRequestApprovalRules_602826(
    name: "overridePullRequestApprovalRules", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.OverridePullRequestApprovalRules",
    validator: validate_OverridePullRequestApprovalRules_602827, base: "/",
    url: url_OverridePullRequestApprovalRules_602828,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentForComparedCommit_602841 = ref object of OpenApiRestCall_601389
proc url_PostCommentForComparedCommit_602843(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCommentForComparedCommit_602842(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602844 = header.getOrDefault("X-Amz-Target")
  valid_602844 = validateParameter(valid_602844, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentForComparedCommit"))
  if valid_602844 != nil:
    section.add "X-Amz-Target", valid_602844
  var valid_602845 = header.getOrDefault("X-Amz-Signature")
  valid_602845 = validateParameter(valid_602845, JString, required = false,
                                 default = nil)
  if valid_602845 != nil:
    section.add "X-Amz-Signature", valid_602845
  var valid_602846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602846 = validateParameter(valid_602846, JString, required = false,
                                 default = nil)
  if valid_602846 != nil:
    section.add "X-Amz-Content-Sha256", valid_602846
  var valid_602847 = header.getOrDefault("X-Amz-Date")
  valid_602847 = validateParameter(valid_602847, JString, required = false,
                                 default = nil)
  if valid_602847 != nil:
    section.add "X-Amz-Date", valid_602847
  var valid_602848 = header.getOrDefault("X-Amz-Credential")
  valid_602848 = validateParameter(valid_602848, JString, required = false,
                                 default = nil)
  if valid_602848 != nil:
    section.add "X-Amz-Credential", valid_602848
  var valid_602849 = header.getOrDefault("X-Amz-Security-Token")
  valid_602849 = validateParameter(valid_602849, JString, required = false,
                                 default = nil)
  if valid_602849 != nil:
    section.add "X-Amz-Security-Token", valid_602849
  var valid_602850 = header.getOrDefault("X-Amz-Algorithm")
  valid_602850 = validateParameter(valid_602850, JString, required = false,
                                 default = nil)
  if valid_602850 != nil:
    section.add "X-Amz-Algorithm", valid_602850
  var valid_602851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602851 = validateParameter(valid_602851, JString, required = false,
                                 default = nil)
  if valid_602851 != nil:
    section.add "X-Amz-SignedHeaders", valid_602851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602853: Call_PostCommentForComparedCommit_602841; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Posts a comment on the comparison between two commits.
  ## 
  let valid = call_602853.validator(path, query, header, formData, body)
  let scheme = call_602853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602853.url(scheme.get, call_602853.host, call_602853.base,
                         call_602853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602853, url, valid)

proc call*(call_602854: Call_PostCommentForComparedCommit_602841; body: JsonNode): Recallable =
  ## postCommentForComparedCommit
  ## Posts a comment on the comparison between two commits.
  ##   body: JObject (required)
  var body_602855 = newJObject()
  if body != nil:
    body_602855 = body
  result = call_602854.call(nil, nil, nil, nil, body_602855)

var postCommentForComparedCommit* = Call_PostCommentForComparedCommit_602841(
    name: "postCommentForComparedCommit", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentForComparedCommit",
    validator: validate_PostCommentForComparedCommit_602842, base: "/",
    url: url_PostCommentForComparedCommit_602843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentForPullRequest_602856 = ref object of OpenApiRestCall_601389
proc url_PostCommentForPullRequest_602858(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCommentForPullRequest_602857(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602859 = header.getOrDefault("X-Amz-Target")
  valid_602859 = validateParameter(valid_602859, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentForPullRequest"))
  if valid_602859 != nil:
    section.add "X-Amz-Target", valid_602859
  var valid_602860 = header.getOrDefault("X-Amz-Signature")
  valid_602860 = validateParameter(valid_602860, JString, required = false,
                                 default = nil)
  if valid_602860 != nil:
    section.add "X-Amz-Signature", valid_602860
  var valid_602861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602861 = validateParameter(valid_602861, JString, required = false,
                                 default = nil)
  if valid_602861 != nil:
    section.add "X-Amz-Content-Sha256", valid_602861
  var valid_602862 = header.getOrDefault("X-Amz-Date")
  valid_602862 = validateParameter(valid_602862, JString, required = false,
                                 default = nil)
  if valid_602862 != nil:
    section.add "X-Amz-Date", valid_602862
  var valid_602863 = header.getOrDefault("X-Amz-Credential")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "X-Amz-Credential", valid_602863
  var valid_602864 = header.getOrDefault("X-Amz-Security-Token")
  valid_602864 = validateParameter(valid_602864, JString, required = false,
                                 default = nil)
  if valid_602864 != nil:
    section.add "X-Amz-Security-Token", valid_602864
  var valid_602865 = header.getOrDefault("X-Amz-Algorithm")
  valid_602865 = validateParameter(valid_602865, JString, required = false,
                                 default = nil)
  if valid_602865 != nil:
    section.add "X-Amz-Algorithm", valid_602865
  var valid_602866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602866 = validateParameter(valid_602866, JString, required = false,
                                 default = nil)
  if valid_602866 != nil:
    section.add "X-Amz-SignedHeaders", valid_602866
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602868: Call_PostCommentForPullRequest_602856; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Posts a comment on a pull request.
  ## 
  let valid = call_602868.validator(path, query, header, formData, body)
  let scheme = call_602868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602868.url(scheme.get, call_602868.host, call_602868.base,
                         call_602868.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602868, url, valid)

proc call*(call_602869: Call_PostCommentForPullRequest_602856; body: JsonNode): Recallable =
  ## postCommentForPullRequest
  ## Posts a comment on a pull request.
  ##   body: JObject (required)
  var body_602870 = newJObject()
  if body != nil:
    body_602870 = body
  result = call_602869.call(nil, nil, nil, nil, body_602870)

var postCommentForPullRequest* = Call_PostCommentForPullRequest_602856(
    name: "postCommentForPullRequest", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentForPullRequest",
    validator: validate_PostCommentForPullRequest_602857, base: "/",
    url: url_PostCommentForPullRequest_602858,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCommentReply_602871 = ref object of OpenApiRestCall_601389
proc url_PostCommentReply_602873(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCommentReply_602872(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602874 = header.getOrDefault("X-Amz-Target")
  valid_602874 = validateParameter(valid_602874, JString, required = true, default = newJString(
      "CodeCommit_20150413.PostCommentReply"))
  if valid_602874 != nil:
    section.add "X-Amz-Target", valid_602874
  var valid_602875 = header.getOrDefault("X-Amz-Signature")
  valid_602875 = validateParameter(valid_602875, JString, required = false,
                                 default = nil)
  if valid_602875 != nil:
    section.add "X-Amz-Signature", valid_602875
  var valid_602876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602876 = validateParameter(valid_602876, JString, required = false,
                                 default = nil)
  if valid_602876 != nil:
    section.add "X-Amz-Content-Sha256", valid_602876
  var valid_602877 = header.getOrDefault("X-Amz-Date")
  valid_602877 = validateParameter(valid_602877, JString, required = false,
                                 default = nil)
  if valid_602877 != nil:
    section.add "X-Amz-Date", valid_602877
  var valid_602878 = header.getOrDefault("X-Amz-Credential")
  valid_602878 = validateParameter(valid_602878, JString, required = false,
                                 default = nil)
  if valid_602878 != nil:
    section.add "X-Amz-Credential", valid_602878
  var valid_602879 = header.getOrDefault("X-Amz-Security-Token")
  valid_602879 = validateParameter(valid_602879, JString, required = false,
                                 default = nil)
  if valid_602879 != nil:
    section.add "X-Amz-Security-Token", valid_602879
  var valid_602880 = header.getOrDefault("X-Amz-Algorithm")
  valid_602880 = validateParameter(valid_602880, JString, required = false,
                                 default = nil)
  if valid_602880 != nil:
    section.add "X-Amz-Algorithm", valid_602880
  var valid_602881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602881 = validateParameter(valid_602881, JString, required = false,
                                 default = nil)
  if valid_602881 != nil:
    section.add "X-Amz-SignedHeaders", valid_602881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602883: Call_PostCommentReply_602871; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Posts a comment in reply to an existing comment on a comparison between commits or a pull request.
  ## 
  let valid = call_602883.validator(path, query, header, formData, body)
  let scheme = call_602883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602883.url(scheme.get, call_602883.host, call_602883.base,
                         call_602883.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602883, url, valid)

proc call*(call_602884: Call_PostCommentReply_602871; body: JsonNode): Recallable =
  ## postCommentReply
  ## Posts a comment in reply to an existing comment on a comparison between commits or a pull request.
  ##   body: JObject (required)
  var body_602885 = newJObject()
  if body != nil:
    body_602885 = body
  result = call_602884.call(nil, nil, nil, nil, body_602885)

var postCommentReply* = Call_PostCommentReply_602871(name: "postCommentReply",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PostCommentReply",
    validator: validate_PostCommentReply_602872, base: "/",
    url: url_PostCommentReply_602873, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFile_602886 = ref object of OpenApiRestCall_601389
proc url_PutFile_602888(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutFile_602887(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602889 = header.getOrDefault("X-Amz-Target")
  valid_602889 = validateParameter(valid_602889, JString, required = true, default = newJString(
      "CodeCommit_20150413.PutFile"))
  if valid_602889 != nil:
    section.add "X-Amz-Target", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-Signature")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-Signature", valid_602890
  var valid_602891 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "X-Amz-Content-Sha256", valid_602891
  var valid_602892 = header.getOrDefault("X-Amz-Date")
  valid_602892 = validateParameter(valid_602892, JString, required = false,
                                 default = nil)
  if valid_602892 != nil:
    section.add "X-Amz-Date", valid_602892
  var valid_602893 = header.getOrDefault("X-Amz-Credential")
  valid_602893 = validateParameter(valid_602893, JString, required = false,
                                 default = nil)
  if valid_602893 != nil:
    section.add "X-Amz-Credential", valid_602893
  var valid_602894 = header.getOrDefault("X-Amz-Security-Token")
  valid_602894 = validateParameter(valid_602894, JString, required = false,
                                 default = nil)
  if valid_602894 != nil:
    section.add "X-Amz-Security-Token", valid_602894
  var valid_602895 = header.getOrDefault("X-Amz-Algorithm")
  valid_602895 = validateParameter(valid_602895, JString, required = false,
                                 default = nil)
  if valid_602895 != nil:
    section.add "X-Amz-Algorithm", valid_602895
  var valid_602896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602896 = validateParameter(valid_602896, JString, required = false,
                                 default = nil)
  if valid_602896 != nil:
    section.add "X-Amz-SignedHeaders", valid_602896
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602898: Call_PutFile_602886; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates a file in a branch in an AWS CodeCommit repository, and generates a commit for the addition in the specified branch.
  ## 
  let valid = call_602898.validator(path, query, header, formData, body)
  let scheme = call_602898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602898.url(scheme.get, call_602898.host, call_602898.base,
                         call_602898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602898, url, valid)

proc call*(call_602899: Call_PutFile_602886; body: JsonNode): Recallable =
  ## putFile
  ## Adds or updates a file in a branch in an AWS CodeCommit repository, and generates a commit for the addition in the specified branch.
  ##   body: JObject (required)
  var body_602900 = newJObject()
  if body != nil:
    body_602900 = body
  result = call_602899.call(nil, nil, nil, nil, body_602900)

var putFile* = Call_PutFile_602886(name: "putFile", meth: HttpMethod.HttpPost,
                                host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.PutFile",
                                validator: validate_PutFile_602887, base: "/",
                                url: url_PutFile_602888,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRepositoryTriggers_602901 = ref object of OpenApiRestCall_601389
proc url_PutRepositoryTriggers_602903(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutRepositoryTriggers_602902(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Replaces all triggers for a repository. Used to create or delete triggers.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602904 = header.getOrDefault("X-Amz-Target")
  valid_602904 = validateParameter(valid_602904, JString, required = true, default = newJString(
      "CodeCommit_20150413.PutRepositoryTriggers"))
  if valid_602904 != nil:
    section.add "X-Amz-Target", valid_602904
  var valid_602905 = header.getOrDefault("X-Amz-Signature")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "X-Amz-Signature", valid_602905
  var valid_602906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "X-Amz-Content-Sha256", valid_602906
  var valid_602907 = header.getOrDefault("X-Amz-Date")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "X-Amz-Date", valid_602907
  var valid_602908 = header.getOrDefault("X-Amz-Credential")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "X-Amz-Credential", valid_602908
  var valid_602909 = header.getOrDefault("X-Amz-Security-Token")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-Security-Token", valid_602909
  var valid_602910 = header.getOrDefault("X-Amz-Algorithm")
  valid_602910 = validateParameter(valid_602910, JString, required = false,
                                 default = nil)
  if valid_602910 != nil:
    section.add "X-Amz-Algorithm", valid_602910
  var valid_602911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602911 = validateParameter(valid_602911, JString, required = false,
                                 default = nil)
  if valid_602911 != nil:
    section.add "X-Amz-SignedHeaders", valid_602911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602913: Call_PutRepositoryTriggers_602901; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces all triggers for a repository. Used to create or delete triggers.
  ## 
  let valid = call_602913.validator(path, query, header, formData, body)
  let scheme = call_602913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602913.url(scheme.get, call_602913.host, call_602913.base,
                         call_602913.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602913, url, valid)

proc call*(call_602914: Call_PutRepositoryTriggers_602901; body: JsonNode): Recallable =
  ## putRepositoryTriggers
  ## Replaces all triggers for a repository. Used to create or delete triggers.
  ##   body: JObject (required)
  var body_602915 = newJObject()
  if body != nil:
    body_602915 = body
  result = call_602914.call(nil, nil, nil, nil, body_602915)

var putRepositoryTriggers* = Call_PutRepositoryTriggers_602901(
    name: "putRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.PutRepositoryTriggers",
    validator: validate_PutRepositoryTriggers_602902, base: "/",
    url: url_PutRepositoryTriggers_602903, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602916 = ref object of OpenApiRestCall_601389
proc url_TagResource_602918(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_602917(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds or updates tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602919 = header.getOrDefault("X-Amz-Target")
  valid_602919 = validateParameter(valid_602919, JString, required = true, default = newJString(
      "CodeCommit_20150413.TagResource"))
  if valid_602919 != nil:
    section.add "X-Amz-Target", valid_602919
  var valid_602920 = header.getOrDefault("X-Amz-Signature")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "X-Amz-Signature", valid_602920
  var valid_602921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-Content-Sha256", valid_602921
  var valid_602922 = header.getOrDefault("X-Amz-Date")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "X-Amz-Date", valid_602922
  var valid_602923 = header.getOrDefault("X-Amz-Credential")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "X-Amz-Credential", valid_602923
  var valid_602924 = header.getOrDefault("X-Amz-Security-Token")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-Security-Token", valid_602924
  var valid_602925 = header.getOrDefault("X-Amz-Algorithm")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Algorithm", valid_602925
  var valid_602926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "X-Amz-SignedHeaders", valid_602926
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602928: Call_TagResource_602916; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ## 
  let valid = call_602928.validator(path, query, header, formData, body)
  let scheme = call_602928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602928.url(scheme.get, call_602928.host, call_602928.base,
                         call_602928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602928, url, valid)

proc call*(call_602929: Call_TagResource_602916; body: JsonNode): Recallable =
  ## tagResource
  ## Adds or updates tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ##   body: JObject (required)
  var body_602930 = newJObject()
  if body != nil:
    body_602930 = body
  result = call_602929.call(nil, nil, nil, nil, body_602930)

var tagResource* = Call_TagResource_602916(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.TagResource",
                                        validator: validate_TagResource_602917,
                                        base: "/", url: url_TagResource_602918,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_TestRepositoryTriggers_602931 = ref object of OpenApiRestCall_601389
proc url_TestRepositoryTriggers_602933(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TestRepositoryTriggers_602932(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Tests the functionality of repository triggers by sending information to the trigger target. If real data is available in the repository, the test sends data from the last commit. If no data is available, sample data is generated.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602934 = header.getOrDefault("X-Amz-Target")
  valid_602934 = validateParameter(valid_602934, JString, required = true, default = newJString(
      "CodeCommit_20150413.TestRepositoryTriggers"))
  if valid_602934 != nil:
    section.add "X-Amz-Target", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Content-Sha256", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Date")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Date", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-Credential")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Credential", valid_602938
  var valid_602939 = header.getOrDefault("X-Amz-Security-Token")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-Security-Token", valid_602939
  var valid_602940 = header.getOrDefault("X-Amz-Algorithm")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "X-Amz-Algorithm", valid_602940
  var valid_602941 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602941 = validateParameter(valid_602941, JString, required = false,
                                 default = nil)
  if valid_602941 != nil:
    section.add "X-Amz-SignedHeaders", valid_602941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602943: Call_TestRepositoryTriggers_602931; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tests the functionality of repository triggers by sending information to the trigger target. If real data is available in the repository, the test sends data from the last commit. If no data is available, sample data is generated.
  ## 
  let valid = call_602943.validator(path, query, header, formData, body)
  let scheme = call_602943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602943.url(scheme.get, call_602943.host, call_602943.base,
                         call_602943.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602943, url, valid)

proc call*(call_602944: Call_TestRepositoryTriggers_602931; body: JsonNode): Recallable =
  ## testRepositoryTriggers
  ## Tests the functionality of repository triggers by sending information to the trigger target. If real data is available in the repository, the test sends data from the last commit. If no data is available, sample data is generated.
  ##   body: JObject (required)
  var body_602945 = newJObject()
  if body != nil:
    body_602945 = body
  result = call_602944.call(nil, nil, nil, nil, body_602945)

var testRepositoryTriggers* = Call_TestRepositoryTriggers_602931(
    name: "testRepositoryTriggers", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.TestRepositoryTriggers",
    validator: validate_TestRepositoryTriggers_602932, base: "/",
    url: url_TestRepositoryTriggers_602933, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602946 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602948(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_602947(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602949 = header.getOrDefault("X-Amz-Target")
  valid_602949 = validateParameter(valid_602949, JString, required = true, default = newJString(
      "CodeCommit_20150413.UntagResource"))
  if valid_602949 != nil:
    section.add "X-Amz-Target", valid_602949
  var valid_602950 = header.getOrDefault("X-Amz-Signature")
  valid_602950 = validateParameter(valid_602950, JString, required = false,
                                 default = nil)
  if valid_602950 != nil:
    section.add "X-Amz-Signature", valid_602950
  var valid_602951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602951 = validateParameter(valid_602951, JString, required = false,
                                 default = nil)
  if valid_602951 != nil:
    section.add "X-Amz-Content-Sha256", valid_602951
  var valid_602952 = header.getOrDefault("X-Amz-Date")
  valid_602952 = validateParameter(valid_602952, JString, required = false,
                                 default = nil)
  if valid_602952 != nil:
    section.add "X-Amz-Date", valid_602952
  var valid_602953 = header.getOrDefault("X-Amz-Credential")
  valid_602953 = validateParameter(valid_602953, JString, required = false,
                                 default = nil)
  if valid_602953 != nil:
    section.add "X-Amz-Credential", valid_602953
  var valid_602954 = header.getOrDefault("X-Amz-Security-Token")
  valid_602954 = validateParameter(valid_602954, JString, required = false,
                                 default = nil)
  if valid_602954 != nil:
    section.add "X-Amz-Security-Token", valid_602954
  var valid_602955 = header.getOrDefault("X-Amz-Algorithm")
  valid_602955 = validateParameter(valid_602955, JString, required = false,
                                 default = nil)
  if valid_602955 != nil:
    section.add "X-Amz-Algorithm", valid_602955
  var valid_602956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602956 = validateParameter(valid_602956, JString, required = false,
                                 default = nil)
  if valid_602956 != nil:
    section.add "X-Amz-SignedHeaders", valid_602956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602958: Call_UntagResource_602946; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ## 
  let valid = call_602958.validator(path, query, header, formData, body)
  let scheme = call_602958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602958.url(scheme.get, call_602958.host, call_602958.base,
                         call_602958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602958, url, valid)

proc call*(call_602959: Call_UntagResource_602946; body: JsonNode): Recallable =
  ## untagResource
  ## Removes tags for a resource in AWS CodeCommit. For a list of valid resources in AWS CodeCommit, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/auth-and-access-control-iam-access-control-identity-based.html#arn-formats">CodeCommit Resources and Operations</a> in the <i>AWS CodeCommit User Guide</i>.
  ##   body: JObject (required)
  var body_602960 = newJObject()
  if body != nil:
    body_602960 = body
  result = call_602959.call(nil, nil, nil, nil, body_602960)

var untagResource* = Call_UntagResource_602946(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UntagResource",
    validator: validate_UntagResource_602947, base: "/", url: url_UntagResource_602948,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApprovalRuleTemplateContent_602961 = ref object of OpenApiRestCall_601389
proc url_UpdateApprovalRuleTemplateContent_602963(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApprovalRuleTemplateContent_602962(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the content of an approval rule template. You can change the number of required approvals, the membership of the approval rule, and whether an approval pool is defined.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602964 = header.getOrDefault("X-Amz-Target")
  valid_602964 = validateParameter(valid_602964, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateApprovalRuleTemplateContent"))
  if valid_602964 != nil:
    section.add "X-Amz-Target", valid_602964
  var valid_602965 = header.getOrDefault("X-Amz-Signature")
  valid_602965 = validateParameter(valid_602965, JString, required = false,
                                 default = nil)
  if valid_602965 != nil:
    section.add "X-Amz-Signature", valid_602965
  var valid_602966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602966 = validateParameter(valid_602966, JString, required = false,
                                 default = nil)
  if valid_602966 != nil:
    section.add "X-Amz-Content-Sha256", valid_602966
  var valid_602967 = header.getOrDefault("X-Amz-Date")
  valid_602967 = validateParameter(valid_602967, JString, required = false,
                                 default = nil)
  if valid_602967 != nil:
    section.add "X-Amz-Date", valid_602967
  var valid_602968 = header.getOrDefault("X-Amz-Credential")
  valid_602968 = validateParameter(valid_602968, JString, required = false,
                                 default = nil)
  if valid_602968 != nil:
    section.add "X-Amz-Credential", valid_602968
  var valid_602969 = header.getOrDefault("X-Amz-Security-Token")
  valid_602969 = validateParameter(valid_602969, JString, required = false,
                                 default = nil)
  if valid_602969 != nil:
    section.add "X-Amz-Security-Token", valid_602969
  var valid_602970 = header.getOrDefault("X-Amz-Algorithm")
  valid_602970 = validateParameter(valid_602970, JString, required = false,
                                 default = nil)
  if valid_602970 != nil:
    section.add "X-Amz-Algorithm", valid_602970
  var valid_602971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602971 = validateParameter(valid_602971, JString, required = false,
                                 default = nil)
  if valid_602971 != nil:
    section.add "X-Amz-SignedHeaders", valid_602971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602973: Call_UpdateApprovalRuleTemplateContent_602961;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the content of an approval rule template. You can change the number of required approvals, the membership of the approval rule, and whether an approval pool is defined.
  ## 
  let valid = call_602973.validator(path, query, header, formData, body)
  let scheme = call_602973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602973.url(scheme.get, call_602973.host, call_602973.base,
                         call_602973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602973, url, valid)

proc call*(call_602974: Call_UpdateApprovalRuleTemplateContent_602961;
          body: JsonNode): Recallable =
  ## updateApprovalRuleTemplateContent
  ## Updates the content of an approval rule template. You can change the number of required approvals, the membership of the approval rule, and whether an approval pool is defined.
  ##   body: JObject (required)
  var body_602975 = newJObject()
  if body != nil:
    body_602975 = body
  result = call_602974.call(nil, nil, nil, nil, body_602975)

var updateApprovalRuleTemplateContent* = Call_UpdateApprovalRuleTemplateContent_602961(
    name: "updateApprovalRuleTemplateContent", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.UpdateApprovalRuleTemplateContent",
    validator: validate_UpdateApprovalRuleTemplateContent_602962, base: "/",
    url: url_UpdateApprovalRuleTemplateContent_602963,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApprovalRuleTemplateDescription_602976 = ref object of OpenApiRestCall_601389
proc url_UpdateApprovalRuleTemplateDescription_602978(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApprovalRuleTemplateDescription_602977(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the description for a specified approval rule template.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602979 = header.getOrDefault("X-Amz-Target")
  valid_602979 = validateParameter(valid_602979, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateApprovalRuleTemplateDescription"))
  if valid_602979 != nil:
    section.add "X-Amz-Target", valid_602979
  var valid_602980 = header.getOrDefault("X-Amz-Signature")
  valid_602980 = validateParameter(valid_602980, JString, required = false,
                                 default = nil)
  if valid_602980 != nil:
    section.add "X-Amz-Signature", valid_602980
  var valid_602981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602981 = validateParameter(valid_602981, JString, required = false,
                                 default = nil)
  if valid_602981 != nil:
    section.add "X-Amz-Content-Sha256", valid_602981
  var valid_602982 = header.getOrDefault("X-Amz-Date")
  valid_602982 = validateParameter(valid_602982, JString, required = false,
                                 default = nil)
  if valid_602982 != nil:
    section.add "X-Amz-Date", valid_602982
  var valid_602983 = header.getOrDefault("X-Amz-Credential")
  valid_602983 = validateParameter(valid_602983, JString, required = false,
                                 default = nil)
  if valid_602983 != nil:
    section.add "X-Amz-Credential", valid_602983
  var valid_602984 = header.getOrDefault("X-Amz-Security-Token")
  valid_602984 = validateParameter(valid_602984, JString, required = false,
                                 default = nil)
  if valid_602984 != nil:
    section.add "X-Amz-Security-Token", valid_602984
  var valid_602985 = header.getOrDefault("X-Amz-Algorithm")
  valid_602985 = validateParameter(valid_602985, JString, required = false,
                                 default = nil)
  if valid_602985 != nil:
    section.add "X-Amz-Algorithm", valid_602985
  var valid_602986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602986 = validateParameter(valid_602986, JString, required = false,
                                 default = nil)
  if valid_602986 != nil:
    section.add "X-Amz-SignedHeaders", valid_602986
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602988: Call_UpdateApprovalRuleTemplateDescription_602976;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the description for a specified approval rule template.
  ## 
  let valid = call_602988.validator(path, query, header, formData, body)
  let scheme = call_602988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602988.url(scheme.get, call_602988.host, call_602988.base,
                         call_602988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602988, url, valid)

proc call*(call_602989: Call_UpdateApprovalRuleTemplateDescription_602976;
          body: JsonNode): Recallable =
  ## updateApprovalRuleTemplateDescription
  ## Updates the description for a specified approval rule template.
  ##   body: JObject (required)
  var body_602990 = newJObject()
  if body != nil:
    body_602990 = body
  result = call_602989.call(nil, nil, nil, nil, body_602990)

var updateApprovalRuleTemplateDescription* = Call_UpdateApprovalRuleTemplateDescription_602976(
    name: "updateApprovalRuleTemplateDescription", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.UpdateApprovalRuleTemplateDescription",
    validator: validate_UpdateApprovalRuleTemplateDescription_602977, base: "/",
    url: url_UpdateApprovalRuleTemplateDescription_602978,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApprovalRuleTemplateName_602991 = ref object of OpenApiRestCall_601389
proc url_UpdateApprovalRuleTemplateName_602993(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApprovalRuleTemplateName_602992(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the name of a specified approval rule template.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602994 = header.getOrDefault("X-Amz-Target")
  valid_602994 = validateParameter(valid_602994, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateApprovalRuleTemplateName"))
  if valid_602994 != nil:
    section.add "X-Amz-Target", valid_602994
  var valid_602995 = header.getOrDefault("X-Amz-Signature")
  valid_602995 = validateParameter(valid_602995, JString, required = false,
                                 default = nil)
  if valid_602995 != nil:
    section.add "X-Amz-Signature", valid_602995
  var valid_602996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602996 = validateParameter(valid_602996, JString, required = false,
                                 default = nil)
  if valid_602996 != nil:
    section.add "X-Amz-Content-Sha256", valid_602996
  var valid_602997 = header.getOrDefault("X-Amz-Date")
  valid_602997 = validateParameter(valid_602997, JString, required = false,
                                 default = nil)
  if valid_602997 != nil:
    section.add "X-Amz-Date", valid_602997
  var valid_602998 = header.getOrDefault("X-Amz-Credential")
  valid_602998 = validateParameter(valid_602998, JString, required = false,
                                 default = nil)
  if valid_602998 != nil:
    section.add "X-Amz-Credential", valid_602998
  var valid_602999 = header.getOrDefault("X-Amz-Security-Token")
  valid_602999 = validateParameter(valid_602999, JString, required = false,
                                 default = nil)
  if valid_602999 != nil:
    section.add "X-Amz-Security-Token", valid_602999
  var valid_603000 = header.getOrDefault("X-Amz-Algorithm")
  valid_603000 = validateParameter(valid_603000, JString, required = false,
                                 default = nil)
  if valid_603000 != nil:
    section.add "X-Amz-Algorithm", valid_603000
  var valid_603001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603001 = validateParameter(valid_603001, JString, required = false,
                                 default = nil)
  if valid_603001 != nil:
    section.add "X-Amz-SignedHeaders", valid_603001
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603003: Call_UpdateApprovalRuleTemplateName_602991; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the name of a specified approval rule template.
  ## 
  let valid = call_603003.validator(path, query, header, formData, body)
  let scheme = call_603003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603003.url(scheme.get, call_603003.host, call_603003.base,
                         call_603003.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603003, url, valid)

proc call*(call_603004: Call_UpdateApprovalRuleTemplateName_602991; body: JsonNode): Recallable =
  ## updateApprovalRuleTemplateName
  ## Updates the name of a specified approval rule template.
  ##   body: JObject (required)
  var body_603005 = newJObject()
  if body != nil:
    body_603005 = body
  result = call_603004.call(nil, nil, nil, nil, body_603005)

var updateApprovalRuleTemplateName* = Call_UpdateApprovalRuleTemplateName_602991(
    name: "updateApprovalRuleTemplateName", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateApprovalRuleTemplateName",
    validator: validate_UpdateApprovalRuleTemplateName_602992, base: "/",
    url: url_UpdateApprovalRuleTemplateName_602993,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateComment_603006 = ref object of OpenApiRestCall_601389
proc url_UpdateComment_603008(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateComment_603007(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603009 = header.getOrDefault("X-Amz-Target")
  valid_603009 = validateParameter(valid_603009, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateComment"))
  if valid_603009 != nil:
    section.add "X-Amz-Target", valid_603009
  var valid_603010 = header.getOrDefault("X-Amz-Signature")
  valid_603010 = validateParameter(valid_603010, JString, required = false,
                                 default = nil)
  if valid_603010 != nil:
    section.add "X-Amz-Signature", valid_603010
  var valid_603011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603011 = validateParameter(valid_603011, JString, required = false,
                                 default = nil)
  if valid_603011 != nil:
    section.add "X-Amz-Content-Sha256", valid_603011
  var valid_603012 = header.getOrDefault("X-Amz-Date")
  valid_603012 = validateParameter(valid_603012, JString, required = false,
                                 default = nil)
  if valid_603012 != nil:
    section.add "X-Amz-Date", valid_603012
  var valid_603013 = header.getOrDefault("X-Amz-Credential")
  valid_603013 = validateParameter(valid_603013, JString, required = false,
                                 default = nil)
  if valid_603013 != nil:
    section.add "X-Amz-Credential", valid_603013
  var valid_603014 = header.getOrDefault("X-Amz-Security-Token")
  valid_603014 = validateParameter(valid_603014, JString, required = false,
                                 default = nil)
  if valid_603014 != nil:
    section.add "X-Amz-Security-Token", valid_603014
  var valid_603015 = header.getOrDefault("X-Amz-Algorithm")
  valid_603015 = validateParameter(valid_603015, JString, required = false,
                                 default = nil)
  if valid_603015 != nil:
    section.add "X-Amz-Algorithm", valid_603015
  var valid_603016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603016 = validateParameter(valid_603016, JString, required = false,
                                 default = nil)
  if valid_603016 != nil:
    section.add "X-Amz-SignedHeaders", valid_603016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603018: Call_UpdateComment_603006; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the contents of a comment.
  ## 
  let valid = call_603018.validator(path, query, header, formData, body)
  let scheme = call_603018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603018.url(scheme.get, call_603018.host, call_603018.base,
                         call_603018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603018, url, valid)

proc call*(call_603019: Call_UpdateComment_603006; body: JsonNode): Recallable =
  ## updateComment
  ## Replaces the contents of a comment.
  ##   body: JObject (required)
  var body_603020 = newJObject()
  if body != nil:
    body_603020 = body
  result = call_603019.call(nil, nil, nil, nil, body_603020)

var updateComment* = Call_UpdateComment_603006(name: "updateComment",
    meth: HttpMethod.HttpPost, host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateComment",
    validator: validate_UpdateComment_603007, base: "/", url: url_UpdateComment_603008,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDefaultBranch_603021 = ref object of OpenApiRestCall_601389
proc url_UpdateDefaultBranch_603023(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDefaultBranch_603022(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603024 = header.getOrDefault("X-Amz-Target")
  valid_603024 = validateParameter(valid_603024, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateDefaultBranch"))
  if valid_603024 != nil:
    section.add "X-Amz-Target", valid_603024
  var valid_603025 = header.getOrDefault("X-Amz-Signature")
  valid_603025 = validateParameter(valid_603025, JString, required = false,
                                 default = nil)
  if valid_603025 != nil:
    section.add "X-Amz-Signature", valid_603025
  var valid_603026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603026 = validateParameter(valid_603026, JString, required = false,
                                 default = nil)
  if valid_603026 != nil:
    section.add "X-Amz-Content-Sha256", valid_603026
  var valid_603027 = header.getOrDefault("X-Amz-Date")
  valid_603027 = validateParameter(valid_603027, JString, required = false,
                                 default = nil)
  if valid_603027 != nil:
    section.add "X-Amz-Date", valid_603027
  var valid_603028 = header.getOrDefault("X-Amz-Credential")
  valid_603028 = validateParameter(valid_603028, JString, required = false,
                                 default = nil)
  if valid_603028 != nil:
    section.add "X-Amz-Credential", valid_603028
  var valid_603029 = header.getOrDefault("X-Amz-Security-Token")
  valid_603029 = validateParameter(valid_603029, JString, required = false,
                                 default = nil)
  if valid_603029 != nil:
    section.add "X-Amz-Security-Token", valid_603029
  var valid_603030 = header.getOrDefault("X-Amz-Algorithm")
  valid_603030 = validateParameter(valid_603030, JString, required = false,
                                 default = nil)
  if valid_603030 != nil:
    section.add "X-Amz-Algorithm", valid_603030
  var valid_603031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603031 = validateParameter(valid_603031, JString, required = false,
                                 default = nil)
  if valid_603031 != nil:
    section.add "X-Amz-SignedHeaders", valid_603031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603033: Call_UpdateDefaultBranch_603021; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or changes the default branch name for the specified repository.</p> <note> <p>If you use this operation to change the default branch name to the current default branch name, a success message is returned even though the default branch did not change.</p> </note>
  ## 
  let valid = call_603033.validator(path, query, header, formData, body)
  let scheme = call_603033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603033.url(scheme.get, call_603033.host, call_603033.base,
                         call_603033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603033, url, valid)

proc call*(call_603034: Call_UpdateDefaultBranch_603021; body: JsonNode): Recallable =
  ## updateDefaultBranch
  ## <p>Sets or changes the default branch name for the specified repository.</p> <note> <p>If you use this operation to change the default branch name to the current default branch name, a success message is returned even though the default branch did not change.</p> </note>
  ##   body: JObject (required)
  var body_603035 = newJObject()
  if body != nil:
    body_603035 = body
  result = call_603034.call(nil, nil, nil, nil, body_603035)

var updateDefaultBranch* = Call_UpdateDefaultBranch_603021(
    name: "updateDefaultBranch", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateDefaultBranch",
    validator: validate_UpdateDefaultBranch_603022, base: "/",
    url: url_UpdateDefaultBranch_603023, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestApprovalRuleContent_603036 = ref object of OpenApiRestCall_601389
proc url_UpdatePullRequestApprovalRuleContent_603038(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestApprovalRuleContent_603037(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the structure of an approval rule created specifically for a pull request. For example, you can change the number of required approvers and the approval pool for approvers. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603039 = header.getOrDefault("X-Amz-Target")
  valid_603039 = validateParameter(valid_603039, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestApprovalRuleContent"))
  if valid_603039 != nil:
    section.add "X-Amz-Target", valid_603039
  var valid_603040 = header.getOrDefault("X-Amz-Signature")
  valid_603040 = validateParameter(valid_603040, JString, required = false,
                                 default = nil)
  if valid_603040 != nil:
    section.add "X-Amz-Signature", valid_603040
  var valid_603041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603041 = validateParameter(valid_603041, JString, required = false,
                                 default = nil)
  if valid_603041 != nil:
    section.add "X-Amz-Content-Sha256", valid_603041
  var valid_603042 = header.getOrDefault("X-Amz-Date")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Date", valid_603042
  var valid_603043 = header.getOrDefault("X-Amz-Credential")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Credential", valid_603043
  var valid_603044 = header.getOrDefault("X-Amz-Security-Token")
  valid_603044 = validateParameter(valid_603044, JString, required = false,
                                 default = nil)
  if valid_603044 != nil:
    section.add "X-Amz-Security-Token", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-Algorithm")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-Algorithm", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-SignedHeaders", valid_603046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603048: Call_UpdatePullRequestApprovalRuleContent_603036;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the structure of an approval rule created specifically for a pull request. For example, you can change the number of required approvers and the approval pool for approvers. 
  ## 
  let valid = call_603048.validator(path, query, header, formData, body)
  let scheme = call_603048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603048.url(scheme.get, call_603048.host, call_603048.base,
                         call_603048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603048, url, valid)

proc call*(call_603049: Call_UpdatePullRequestApprovalRuleContent_603036;
          body: JsonNode): Recallable =
  ## updatePullRequestApprovalRuleContent
  ## Updates the structure of an approval rule created specifically for a pull request. For example, you can change the number of required approvers and the approval pool for approvers. 
  ##   body: JObject (required)
  var body_603050 = newJObject()
  if body != nil:
    body_603050 = body
  result = call_603049.call(nil, nil, nil, nil, body_603050)

var updatePullRequestApprovalRuleContent* = Call_UpdatePullRequestApprovalRuleContent_603036(
    name: "updatePullRequestApprovalRuleContent", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com", route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestApprovalRuleContent",
    validator: validate_UpdatePullRequestApprovalRuleContent_603037, base: "/",
    url: url_UpdatePullRequestApprovalRuleContent_603038,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestApprovalState_603051 = ref object of OpenApiRestCall_601389
proc url_UpdatePullRequestApprovalState_603053(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestApprovalState_603052(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the state of a user's approval on a pull request. The user is derived from the signed-in account when the request is made.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603054 = header.getOrDefault("X-Amz-Target")
  valid_603054 = validateParameter(valid_603054, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestApprovalState"))
  if valid_603054 != nil:
    section.add "X-Amz-Target", valid_603054
  var valid_603055 = header.getOrDefault("X-Amz-Signature")
  valid_603055 = validateParameter(valid_603055, JString, required = false,
                                 default = nil)
  if valid_603055 != nil:
    section.add "X-Amz-Signature", valid_603055
  var valid_603056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603056 = validateParameter(valid_603056, JString, required = false,
                                 default = nil)
  if valid_603056 != nil:
    section.add "X-Amz-Content-Sha256", valid_603056
  var valid_603057 = header.getOrDefault("X-Amz-Date")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "X-Amz-Date", valid_603057
  var valid_603058 = header.getOrDefault("X-Amz-Credential")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "X-Amz-Credential", valid_603058
  var valid_603059 = header.getOrDefault("X-Amz-Security-Token")
  valid_603059 = validateParameter(valid_603059, JString, required = false,
                                 default = nil)
  if valid_603059 != nil:
    section.add "X-Amz-Security-Token", valid_603059
  var valid_603060 = header.getOrDefault("X-Amz-Algorithm")
  valid_603060 = validateParameter(valid_603060, JString, required = false,
                                 default = nil)
  if valid_603060 != nil:
    section.add "X-Amz-Algorithm", valid_603060
  var valid_603061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-SignedHeaders", valid_603061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603063: Call_UpdatePullRequestApprovalState_603051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the state of a user's approval on a pull request. The user is derived from the signed-in account when the request is made.
  ## 
  let valid = call_603063.validator(path, query, header, formData, body)
  let scheme = call_603063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603063.url(scheme.get, call_603063.host, call_603063.base,
                         call_603063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603063, url, valid)

proc call*(call_603064: Call_UpdatePullRequestApprovalState_603051; body: JsonNode): Recallable =
  ## updatePullRequestApprovalState
  ## Updates the state of a user's approval on a pull request. The user is derived from the signed-in account when the request is made.
  ##   body: JObject (required)
  var body_603065 = newJObject()
  if body != nil:
    body_603065 = body
  result = call_603064.call(nil, nil, nil, nil, body_603065)

var updatePullRequestApprovalState* = Call_UpdatePullRequestApprovalState_603051(
    name: "updatePullRequestApprovalState", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestApprovalState",
    validator: validate_UpdatePullRequestApprovalState_603052, base: "/",
    url: url_UpdatePullRequestApprovalState_603053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestDescription_603066 = ref object of OpenApiRestCall_601389
proc url_UpdatePullRequestDescription_603068(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestDescription_603067(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603069 = header.getOrDefault("X-Amz-Target")
  valid_603069 = validateParameter(valid_603069, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestDescription"))
  if valid_603069 != nil:
    section.add "X-Amz-Target", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Signature")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Signature", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Content-Sha256", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-Date")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Date", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Credential")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Credential", valid_603073
  var valid_603074 = header.getOrDefault("X-Amz-Security-Token")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-Security-Token", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-Algorithm")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Algorithm", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-SignedHeaders", valid_603076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603078: Call_UpdatePullRequestDescription_603066; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the contents of the description of a pull request.
  ## 
  let valid = call_603078.validator(path, query, header, formData, body)
  let scheme = call_603078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603078.url(scheme.get, call_603078.host, call_603078.base,
                         call_603078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603078, url, valid)

proc call*(call_603079: Call_UpdatePullRequestDescription_603066; body: JsonNode): Recallable =
  ## updatePullRequestDescription
  ## Replaces the contents of the description of a pull request.
  ##   body: JObject (required)
  var body_603080 = newJObject()
  if body != nil:
    body_603080 = body
  result = call_603079.call(nil, nil, nil, nil, body_603080)

var updatePullRequestDescription* = Call_UpdatePullRequestDescription_603066(
    name: "updatePullRequestDescription", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestDescription",
    validator: validate_UpdatePullRequestDescription_603067, base: "/",
    url: url_UpdatePullRequestDescription_603068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestStatus_603081 = ref object of OpenApiRestCall_601389
proc url_UpdatePullRequestStatus_603083(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestStatus_603082(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603084 = header.getOrDefault("X-Amz-Target")
  valid_603084 = validateParameter(valid_603084, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestStatus"))
  if valid_603084 != nil:
    section.add "X-Amz-Target", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Signature")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Signature", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Content-Sha256", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-Date")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Date", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Credential")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Credential", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-Security-Token")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Security-Token", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Algorithm")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Algorithm", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-SignedHeaders", valid_603091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603093: Call_UpdatePullRequestStatus_603081; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the status of a pull request. 
  ## 
  let valid = call_603093.validator(path, query, header, formData, body)
  let scheme = call_603093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603093.url(scheme.get, call_603093.host, call_603093.base,
                         call_603093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603093, url, valid)

proc call*(call_603094: Call_UpdatePullRequestStatus_603081; body: JsonNode): Recallable =
  ## updatePullRequestStatus
  ## Updates the status of a pull request. 
  ##   body: JObject (required)
  var body_603095 = newJObject()
  if body != nil:
    body_603095 = body
  result = call_603094.call(nil, nil, nil, nil, body_603095)

var updatePullRequestStatus* = Call_UpdatePullRequestStatus_603081(
    name: "updatePullRequestStatus", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestStatus",
    validator: validate_UpdatePullRequestStatus_603082, base: "/",
    url: url_UpdatePullRequestStatus_603083, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePullRequestTitle_603096 = ref object of OpenApiRestCall_601389
proc url_UpdatePullRequestTitle_603098(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePullRequestTitle_603097(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603099 = header.getOrDefault("X-Amz-Target")
  valid_603099 = validateParameter(valid_603099, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdatePullRequestTitle"))
  if valid_603099 != nil:
    section.add "X-Amz-Target", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Signature")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Signature", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Content-Sha256", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Date")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Date", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Credential")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Credential", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Security-Token")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Security-Token", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Algorithm")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Algorithm", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-SignedHeaders", valid_603106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603108: Call_UpdatePullRequestTitle_603096; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Replaces the title of a pull request.
  ## 
  let valid = call_603108.validator(path, query, header, formData, body)
  let scheme = call_603108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603108.url(scheme.get, call_603108.host, call_603108.base,
                         call_603108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603108, url, valid)

proc call*(call_603109: Call_UpdatePullRequestTitle_603096; body: JsonNode): Recallable =
  ## updatePullRequestTitle
  ## Replaces the title of a pull request.
  ##   body: JObject (required)
  var body_603110 = newJObject()
  if body != nil:
    body_603110 = body
  result = call_603109.call(nil, nil, nil, nil, body_603110)

var updatePullRequestTitle* = Call_UpdatePullRequestTitle_603096(
    name: "updatePullRequestTitle", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdatePullRequestTitle",
    validator: validate_UpdatePullRequestTitle_603097, base: "/",
    url: url_UpdatePullRequestTitle_603098, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRepositoryDescription_603111 = ref object of OpenApiRestCall_601389
proc url_UpdateRepositoryDescription_603113(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRepositoryDescription_603112(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets or changes the comment or description for a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603114 = header.getOrDefault("X-Amz-Target")
  valid_603114 = validateParameter(valid_603114, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateRepositoryDescription"))
  if valid_603114 != nil:
    section.add "X-Amz-Target", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Signature")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Signature", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Content-Sha256", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Date")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Date", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Credential")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Credential", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Security-Token")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Security-Token", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Algorithm")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Algorithm", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-SignedHeaders", valid_603121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603123: Call_UpdateRepositoryDescription_603111; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets or changes the comment or description for a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ## 
  let valid = call_603123.validator(path, query, header, formData, body)
  let scheme = call_603123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603123.url(scheme.get, call_603123.host, call_603123.base,
                         call_603123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603123, url, valid)

proc call*(call_603124: Call_UpdateRepositoryDescription_603111; body: JsonNode): Recallable =
  ## updateRepositoryDescription
  ## <p>Sets or changes the comment or description for a repository.</p> <note> <p>The description field for a repository accepts all HTML characters and all valid Unicode characters. Applications that do not HTML-encode the description and display it in a webpage can expose users to potentially malicious code. Make sure that you HTML-encode the description field in any application that uses this API to display the repository description on a webpage.</p> </note>
  ##   body: JObject (required)
  var body_603125 = newJObject()
  if body != nil:
    body_603125 = body
  result = call_603124.call(nil, nil, nil, nil, body_603125)

var updateRepositoryDescription* = Call_UpdateRepositoryDescription_603111(
    name: "updateRepositoryDescription", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateRepositoryDescription",
    validator: validate_UpdateRepositoryDescription_603112, base: "/",
    url: url_UpdateRepositoryDescription_603113,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRepositoryName_603126 = ref object of OpenApiRestCall_601389
proc url_UpdateRepositoryName_603128(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRepositoryName_603127(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Renames a repository. The repository name must be unique across the calling AWS account. Repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. The suffix .git is prohibited. For more information about the limits on repository names, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html">Limits</a> in the AWS CodeCommit User Guide.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603129 = header.getOrDefault("X-Amz-Target")
  valid_603129 = validateParameter(valid_603129, JString, required = true, default = newJString(
      "CodeCommit_20150413.UpdateRepositoryName"))
  if valid_603129 != nil:
    section.add "X-Amz-Target", valid_603129
  var valid_603130 = header.getOrDefault("X-Amz-Signature")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Signature", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-Content-Sha256", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-Date")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Date", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Credential")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Credential", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Security-Token")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Security-Token", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Algorithm")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Algorithm", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-SignedHeaders", valid_603136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603138: Call_UpdateRepositoryName_603126; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Renames a repository. The repository name must be unique across the calling AWS account. Repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. The suffix .git is prohibited. For more information about the limits on repository names, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html">Limits</a> in the AWS CodeCommit User Guide.
  ## 
  let valid = call_603138.validator(path, query, header, formData, body)
  let scheme = call_603138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603138.url(scheme.get, call_603138.host, call_603138.base,
                         call_603138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603138, url, valid)

proc call*(call_603139: Call_UpdateRepositoryName_603126; body: JsonNode): Recallable =
  ## updateRepositoryName
  ## Renames a repository. The repository name must be unique across the calling AWS account. Repository names are limited to 100 alphanumeric, dash, and underscore characters, and cannot include certain characters. The suffix .git is prohibited. For more information about the limits on repository names, see <a href="https://docs.aws.amazon.com/codecommit/latest/userguide/limits.html">Limits</a> in the AWS CodeCommit User Guide.
  ##   body: JObject (required)
  var body_603140 = newJObject()
  if body != nil:
    body_603140 = body
  result = call_603139.call(nil, nil, nil, nil, body_603140)

var updateRepositoryName* = Call_UpdateRepositoryName_603126(
    name: "updateRepositoryName", meth: HttpMethod.HttpPost,
    host: "codecommit.amazonaws.com",
    route: "/#X-Amz-Target=CodeCommit_20150413.UpdateRepositoryName",
    validator: validate_UpdateRepositoryName_603127, base: "/",
    url: url_UpdateRepositoryName_603128, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
