
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CodeGuru Reviewer
## version: 2019-09-19
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## This section provides documentation for the Amazon CodeGuru Reviewer API operations.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/codeguru-reviewer/
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

  OpenApiRestCall_601380 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601380](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601380): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "codeguru-reviewer.ap-northeast-1.amazonaws.com", "ap-southeast-1": "codeguru-reviewer.ap-southeast-1.amazonaws.com", "us-west-2": "codeguru-reviewer.us-west-2.amazonaws.com", "eu-west-2": "codeguru-reviewer.eu-west-2.amazonaws.com", "ap-northeast-3": "codeguru-reviewer.ap-northeast-3.amazonaws.com", "eu-central-1": "codeguru-reviewer.eu-central-1.amazonaws.com", "us-east-2": "codeguru-reviewer.us-east-2.amazonaws.com", "us-east-1": "codeguru-reviewer.us-east-1.amazonaws.com", "cn-northwest-1": "codeguru-reviewer.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "codeguru-reviewer.ap-south-1.amazonaws.com", "eu-north-1": "codeguru-reviewer.eu-north-1.amazonaws.com", "ap-northeast-2": "codeguru-reviewer.ap-northeast-2.amazonaws.com", "us-west-1": "codeguru-reviewer.us-west-1.amazonaws.com", "us-gov-east-1": "codeguru-reviewer.us-gov-east-1.amazonaws.com", "eu-west-3": "codeguru-reviewer.eu-west-3.amazonaws.com", "cn-north-1": "codeguru-reviewer.cn-north-1.amazonaws.com.cn", "sa-east-1": "codeguru-reviewer.sa-east-1.amazonaws.com", "eu-west-1": "codeguru-reviewer.eu-west-1.amazonaws.com", "us-gov-west-1": "codeguru-reviewer.us-gov-west-1.amazonaws.com", "ap-southeast-2": "codeguru-reviewer.ap-southeast-2.amazonaws.com", "ca-central-1": "codeguru-reviewer.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "codeguru-reviewer.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "codeguru-reviewer.ap-southeast-1.amazonaws.com",
      "us-west-2": "codeguru-reviewer.us-west-2.amazonaws.com",
      "eu-west-2": "codeguru-reviewer.eu-west-2.amazonaws.com",
      "ap-northeast-3": "codeguru-reviewer.ap-northeast-3.amazonaws.com",
      "eu-central-1": "codeguru-reviewer.eu-central-1.amazonaws.com",
      "us-east-2": "codeguru-reviewer.us-east-2.amazonaws.com",
      "us-east-1": "codeguru-reviewer.us-east-1.amazonaws.com",
      "cn-northwest-1": "codeguru-reviewer.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "codeguru-reviewer.ap-south-1.amazonaws.com",
      "eu-north-1": "codeguru-reviewer.eu-north-1.amazonaws.com",
      "ap-northeast-2": "codeguru-reviewer.ap-northeast-2.amazonaws.com",
      "us-west-1": "codeguru-reviewer.us-west-1.amazonaws.com",
      "us-gov-east-1": "codeguru-reviewer.us-gov-east-1.amazonaws.com",
      "eu-west-3": "codeguru-reviewer.eu-west-3.amazonaws.com",
      "cn-north-1": "codeguru-reviewer.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "codeguru-reviewer.sa-east-1.amazonaws.com",
      "eu-west-1": "codeguru-reviewer.eu-west-1.amazonaws.com",
      "us-gov-west-1": "codeguru-reviewer.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "codeguru-reviewer.ap-southeast-2.amazonaws.com",
      "ca-central-1": "codeguru-reviewer.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "codeguru-reviewer"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateRepository_601979 = ref object of OpenApiRestCall_601380
proc url_AssociateRepository_601981(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateRepository_601980(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Associates an AWS CodeCommit repository with Amazon CodeGuru Reviewer. When you associate an AWS CodeCommit repository with Amazon CodeGuru Reviewer, Amazon CodeGuru Reviewer will provide recommendations for each pull request. You can view recommendations in the AWS CodeCommit repository.</p> <p>You can associate a GitHub repository using the Amazon CodeGuru Reviewer console.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601982 = header.getOrDefault("X-Amz-Signature")
  valid_601982 = validateParameter(valid_601982, JString, required = false,
                                 default = nil)
  if valid_601982 != nil:
    section.add "X-Amz-Signature", valid_601982
  var valid_601983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601983 = validateParameter(valid_601983, JString, required = false,
                                 default = nil)
  if valid_601983 != nil:
    section.add "X-Amz-Content-Sha256", valid_601983
  var valid_601984 = header.getOrDefault("X-Amz-Date")
  valid_601984 = validateParameter(valid_601984, JString, required = false,
                                 default = nil)
  if valid_601984 != nil:
    section.add "X-Amz-Date", valid_601984
  var valid_601985 = header.getOrDefault("X-Amz-Credential")
  valid_601985 = validateParameter(valid_601985, JString, required = false,
                                 default = nil)
  if valid_601985 != nil:
    section.add "X-Amz-Credential", valid_601985
  var valid_601986 = header.getOrDefault("X-Amz-Security-Token")
  valid_601986 = validateParameter(valid_601986, JString, required = false,
                                 default = nil)
  if valid_601986 != nil:
    section.add "X-Amz-Security-Token", valid_601986
  var valid_601987 = header.getOrDefault("X-Amz-Algorithm")
  valid_601987 = validateParameter(valid_601987, JString, required = false,
                                 default = nil)
  if valid_601987 != nil:
    section.add "X-Amz-Algorithm", valid_601987
  var valid_601988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "X-Amz-SignedHeaders", valid_601988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601990: Call_AssociateRepository_601979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates an AWS CodeCommit repository with Amazon CodeGuru Reviewer. When you associate an AWS CodeCommit repository with Amazon CodeGuru Reviewer, Amazon CodeGuru Reviewer will provide recommendations for each pull request. You can view recommendations in the AWS CodeCommit repository.</p> <p>You can associate a GitHub repository using the Amazon CodeGuru Reviewer console.</p>
  ## 
  let valid = call_601990.validator(path, query, header, formData, body)
  let scheme = call_601990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601990.url(scheme.get, call_601990.host, call_601990.base,
                         call_601990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601990, url, valid)

proc call*(call_601991: Call_AssociateRepository_601979; body: JsonNode): Recallable =
  ## associateRepository
  ## <p>Associates an AWS CodeCommit repository with Amazon CodeGuru Reviewer. When you associate an AWS CodeCommit repository with Amazon CodeGuru Reviewer, Amazon CodeGuru Reviewer will provide recommendations for each pull request. You can view recommendations in the AWS CodeCommit repository.</p> <p>You can associate a GitHub repository using the Amazon CodeGuru Reviewer console.</p>
  ##   body: JObject (required)
  var body_601992 = newJObject()
  if body != nil:
    body_601992 = body
  result = call_601991.call(nil, nil, nil, nil, body_601992)

var associateRepository* = Call_AssociateRepository_601979(
    name: "associateRepository", meth: HttpMethod.HttpPost,
    host: "codeguru-reviewer.amazonaws.com", route: "/associations",
    validator: validate_AssociateRepository_601980, base: "/",
    url: url_AssociateRepository_601981, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRepositoryAssociations_601718 = ref object of OpenApiRestCall_601380
proc url_ListRepositoryAssociations_601720(protocol: Scheme; host: string;
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

proc validate_ListRepositoryAssociations_601719(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists repository associations. You can optionally filter on one or more of the following recommendation properties: provider types, states, names, and owners.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : The maximum number of repository association results returned by <code>ListRepositoryAssociations</code> in paginated output. When this parameter is used, <code>ListRepositoryAssociations</code> only returns <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. The remaining results of the initial request can be seen by sending another <code>ListRepositoryAssociations</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If this parameter is not used, then <code>ListRepositoryAssociations</code> returns up to 100 results and a <code>nextToken</code> value if applicable. 
  ##   Owner: JArray
  ##        : List of owners to use as a filter. For AWS CodeCommit, the owner is the AWS account id. For GitHub, it is the GitHub account name.
  ##   State: JArray
  ##        : List of states to use as a filter.
  ##   NextToken: JString
  ##            : <p>The <code>nextToken</code> value returned from a previous paginated <code>ListRepositoryAssociations</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value. </p> <note> <p>This token should be treated as an opaque identifier that is only used to retrieve the next items in a list and not for other programmatic purposes.</p> </note>
  ##   ProviderType: JArray
  ##               : List of provider types to use as a filter.
  ##   Name: JArray
  ##       : List of names to use as a filter.
  section = newJObject()
  var valid_601832 = query.getOrDefault("MaxResults")
  valid_601832 = validateParameter(valid_601832, JInt, required = false, default = nil)
  if valid_601832 != nil:
    section.add "MaxResults", valid_601832
  var valid_601833 = query.getOrDefault("Owner")
  valid_601833 = validateParameter(valid_601833, JArray, required = false,
                                 default = nil)
  if valid_601833 != nil:
    section.add "Owner", valid_601833
  var valid_601834 = query.getOrDefault("State")
  valid_601834 = validateParameter(valid_601834, JArray, required = false,
                                 default = nil)
  if valid_601834 != nil:
    section.add "State", valid_601834
  var valid_601835 = query.getOrDefault("NextToken")
  valid_601835 = validateParameter(valid_601835, JString, required = false,
                                 default = nil)
  if valid_601835 != nil:
    section.add "NextToken", valid_601835
  var valid_601836 = query.getOrDefault("ProviderType")
  valid_601836 = validateParameter(valid_601836, JArray, required = false,
                                 default = nil)
  if valid_601836 != nil:
    section.add "ProviderType", valid_601836
  var valid_601837 = query.getOrDefault("Name")
  valid_601837 = validateParameter(valid_601837, JArray, required = false,
                                 default = nil)
  if valid_601837 != nil:
    section.add "Name", valid_601837
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601838 = header.getOrDefault("X-Amz-Signature")
  valid_601838 = validateParameter(valid_601838, JString, required = false,
                                 default = nil)
  if valid_601838 != nil:
    section.add "X-Amz-Signature", valid_601838
  var valid_601839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601839 = validateParameter(valid_601839, JString, required = false,
                                 default = nil)
  if valid_601839 != nil:
    section.add "X-Amz-Content-Sha256", valid_601839
  var valid_601840 = header.getOrDefault("X-Amz-Date")
  valid_601840 = validateParameter(valid_601840, JString, required = false,
                                 default = nil)
  if valid_601840 != nil:
    section.add "X-Amz-Date", valid_601840
  var valid_601841 = header.getOrDefault("X-Amz-Credential")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-Credential", valid_601841
  var valid_601842 = header.getOrDefault("X-Amz-Security-Token")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Security-Token", valid_601842
  var valid_601843 = header.getOrDefault("X-Amz-Algorithm")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Algorithm", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-SignedHeaders", valid_601844
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601867: Call_ListRepositoryAssociations_601718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists repository associations. You can optionally filter on one or more of the following recommendation properties: provider types, states, names, and owners.
  ## 
  let valid = call_601867.validator(path, query, header, formData, body)
  let scheme = call_601867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601867.url(scheme.get, call_601867.host, call_601867.base,
                         call_601867.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601867, url, valid)

proc call*(call_601938: Call_ListRepositoryAssociations_601718;
          MaxResults: int = 0; Owner: JsonNode = nil; State: JsonNode = nil;
          NextToken: string = ""; ProviderType: JsonNode = nil; Name: JsonNode = nil): Recallable =
  ## listRepositoryAssociations
  ## Lists repository associations. You can optionally filter on one or more of the following recommendation properties: provider types, states, names, and owners.
  ##   MaxResults: int
  ##             : The maximum number of repository association results returned by <code>ListRepositoryAssociations</code> in paginated output. When this parameter is used, <code>ListRepositoryAssociations</code> only returns <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. The remaining results of the initial request can be seen by sending another <code>ListRepositoryAssociations</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If this parameter is not used, then <code>ListRepositoryAssociations</code> returns up to 100 results and a <code>nextToken</code> value if applicable. 
  ##   Owner: JArray
  ##        : List of owners to use as a filter. For AWS CodeCommit, the owner is the AWS account id. For GitHub, it is the GitHub account name.
  ##   State: JArray
  ##        : List of states to use as a filter.
  ##   NextToken: string
  ##            : <p>The <code>nextToken</code> value returned from a previous paginated <code>ListRepositoryAssociations</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value. </p> <note> <p>This token should be treated as an opaque identifier that is only used to retrieve the next items in a list and not for other programmatic purposes.</p> </note>
  ##   ProviderType: JArray
  ##               : List of provider types to use as a filter.
  ##   Name: JArray
  ##       : List of names to use as a filter.
  var query_601939 = newJObject()
  add(query_601939, "MaxResults", newJInt(MaxResults))
  if Owner != nil:
    query_601939.add "Owner", Owner
  if State != nil:
    query_601939.add "State", State
  add(query_601939, "NextToken", newJString(NextToken))
  if ProviderType != nil:
    query_601939.add "ProviderType", ProviderType
  if Name != nil:
    query_601939.add "Name", Name
  result = call_601938.call(nil, query_601939, nil, nil, nil)

var listRepositoryAssociations* = Call_ListRepositoryAssociations_601718(
    name: "listRepositoryAssociations", meth: HttpMethod.HttpGet,
    host: "codeguru-reviewer.amazonaws.com", route: "/associations",
    validator: validate_ListRepositoryAssociations_601719, base: "/",
    url: url_ListRepositoryAssociations_601720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRepositoryAssociation_601993 = ref object of OpenApiRestCall_601380
proc url_DescribeRepositoryAssociation_601995(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AssociationArn" in path, "`AssociationArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/associations/"),
               (kind: VariableSegment, value: "AssociationArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeRepositoryAssociation_601994(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a repository association.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AssociationArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) identifying the association.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AssociationArn` field"
  var valid_602010 = path.getOrDefault("AssociationArn")
  valid_602010 = validateParameter(valid_602010, JString, required = true,
                                 default = nil)
  if valid_602010 != nil:
    section.add "AssociationArn", valid_602010
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602011 = header.getOrDefault("X-Amz-Signature")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Signature", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-Content-Sha256", valid_602012
  var valid_602013 = header.getOrDefault("X-Amz-Date")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-Date", valid_602013
  var valid_602014 = header.getOrDefault("X-Amz-Credential")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-Credential", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Security-Token")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Security-Token", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Algorithm")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Algorithm", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-SignedHeaders", valid_602017
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602018: Call_DescribeRepositoryAssociation_601993; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a repository association.
  ## 
  let valid = call_602018.validator(path, query, header, formData, body)
  let scheme = call_602018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602018.url(scheme.get, call_602018.host, call_602018.base,
                         call_602018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602018, url, valid)

proc call*(call_602019: Call_DescribeRepositoryAssociation_601993;
          AssociationArn: string): Recallable =
  ## describeRepositoryAssociation
  ## Describes a repository association.
  ##   AssociationArn: string (required)
  ##                 : The Amazon Resource Name (ARN) identifying the association.
  var path_602020 = newJObject()
  add(path_602020, "AssociationArn", newJString(AssociationArn))
  result = call_602019.call(path_602020, nil, nil, nil, nil)

var describeRepositoryAssociation* = Call_DescribeRepositoryAssociation_601993(
    name: "describeRepositoryAssociation", meth: HttpMethod.HttpGet,
    host: "codeguru-reviewer.amazonaws.com",
    route: "/associations/{AssociationArn}",
    validator: validate_DescribeRepositoryAssociation_601994, base: "/",
    url: url_DescribeRepositoryAssociation_601995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateRepository_602021 = ref object of OpenApiRestCall_601380
proc url_DisassociateRepository_602023(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AssociationArn" in path, "`AssociationArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/associations/"),
               (kind: VariableSegment, value: "AssociationArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateRepository_602022(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the association between Amazon CodeGuru Reviewer and a repository.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AssociationArn: JString (required)
  ##                 : The Amazon Resource Name (ARN) identifying the association.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AssociationArn` field"
  var valid_602024 = path.getOrDefault("AssociationArn")
  valid_602024 = validateParameter(valid_602024, JString, required = true,
                                 default = nil)
  if valid_602024 != nil:
    section.add "AssociationArn", valid_602024
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602025 = header.getOrDefault("X-Amz-Signature")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Signature", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Content-Sha256", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Date")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Date", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Credential")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Credential", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Security-Token")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Security-Token", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Algorithm")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Algorithm", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-SignedHeaders", valid_602031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602032: Call_DisassociateRepository_602021; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the association between Amazon CodeGuru Reviewer and a repository.
  ## 
  let valid = call_602032.validator(path, query, header, formData, body)
  let scheme = call_602032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602032.url(scheme.get, call_602032.host, call_602032.base,
                         call_602032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602032, url, valid)

proc call*(call_602033: Call_DisassociateRepository_602021; AssociationArn: string): Recallable =
  ## disassociateRepository
  ## Removes the association between Amazon CodeGuru Reviewer and a repository.
  ##   AssociationArn: string (required)
  ##                 : The Amazon Resource Name (ARN) identifying the association.
  var path_602034 = newJObject()
  add(path_602034, "AssociationArn", newJString(AssociationArn))
  result = call_602033.call(path_602034, nil, nil, nil, nil)

var disassociateRepository* = Call_DisassociateRepository_602021(
    name: "disassociateRepository", meth: HttpMethod.HttpDelete,
    host: "codeguru-reviewer.amazonaws.com",
    route: "/associations/{AssociationArn}",
    validator: validate_DisassociateRepository_602022, base: "/",
    url: url_DisassociateRepository_602023, schemes: {Scheme.Https, Scheme.Http})
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
