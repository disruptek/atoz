
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

  OpenApiRestCall_597380 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_597380](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_597380): Option[Scheme] {.used.} =
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
  Call_AssociateRepository_597979 = ref object of OpenApiRestCall_597380
proc url_AssociateRepository_597981(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateRepository_597980(path: JsonNode; query: JsonNode;
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
  var valid_597982 = header.getOrDefault("X-Amz-Signature")
  valid_597982 = validateParameter(valid_597982, JString, required = false,
                                 default = nil)
  if valid_597982 != nil:
    section.add "X-Amz-Signature", valid_597982
  var valid_597983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597983 = validateParameter(valid_597983, JString, required = false,
                                 default = nil)
  if valid_597983 != nil:
    section.add "X-Amz-Content-Sha256", valid_597983
  var valid_597984 = header.getOrDefault("X-Amz-Date")
  valid_597984 = validateParameter(valid_597984, JString, required = false,
                                 default = nil)
  if valid_597984 != nil:
    section.add "X-Amz-Date", valid_597984
  var valid_597985 = header.getOrDefault("X-Amz-Credential")
  valid_597985 = validateParameter(valid_597985, JString, required = false,
                                 default = nil)
  if valid_597985 != nil:
    section.add "X-Amz-Credential", valid_597985
  var valid_597986 = header.getOrDefault("X-Amz-Security-Token")
  valid_597986 = validateParameter(valid_597986, JString, required = false,
                                 default = nil)
  if valid_597986 != nil:
    section.add "X-Amz-Security-Token", valid_597986
  var valid_597987 = header.getOrDefault("X-Amz-Algorithm")
  valid_597987 = validateParameter(valid_597987, JString, required = false,
                                 default = nil)
  if valid_597987 != nil:
    section.add "X-Amz-Algorithm", valid_597987
  var valid_597988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597988 = validateParameter(valid_597988, JString, required = false,
                                 default = nil)
  if valid_597988 != nil:
    section.add "X-Amz-SignedHeaders", valid_597988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_597990: Call_AssociateRepository_597979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates an AWS CodeCommit repository with Amazon CodeGuru Reviewer. When you associate an AWS CodeCommit repository with Amazon CodeGuru Reviewer, Amazon CodeGuru Reviewer will provide recommendations for each pull request. You can view recommendations in the AWS CodeCommit repository.</p> <p>You can associate a GitHub repository using the Amazon CodeGuru Reviewer console.</p>
  ## 
  let valid = call_597990.validator(path, query, header, formData, body)
  let scheme = call_597990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597990.url(scheme.get, call_597990.host, call_597990.base,
                         call_597990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597990, url, valid)

proc call*(call_597991: Call_AssociateRepository_597979; body: JsonNode): Recallable =
  ## associateRepository
  ## <p>Associates an AWS CodeCommit repository with Amazon CodeGuru Reviewer. When you associate an AWS CodeCommit repository with Amazon CodeGuru Reviewer, Amazon CodeGuru Reviewer will provide recommendations for each pull request. You can view recommendations in the AWS CodeCommit repository.</p> <p>You can associate a GitHub repository using the Amazon CodeGuru Reviewer console.</p>
  ##   body: JObject (required)
  var body_597992 = newJObject()
  if body != nil:
    body_597992 = body
  result = call_597991.call(nil, nil, nil, nil, body_597992)

var associateRepository* = Call_AssociateRepository_597979(
    name: "associateRepository", meth: HttpMethod.HttpPost,
    host: "codeguru-reviewer.amazonaws.com", route: "/associations",
    validator: validate_AssociateRepository_597980, base: "/",
    url: url_AssociateRepository_597981, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRepositoryAssociations_597718 = ref object of OpenApiRestCall_597380
proc url_ListRepositoryAssociations_597720(protocol: Scheme; host: string;
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

proc validate_ListRepositoryAssociations_597719(path: JsonNode; query: JsonNode;
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
  var valid_597832 = query.getOrDefault("MaxResults")
  valid_597832 = validateParameter(valid_597832, JInt, required = false, default = nil)
  if valid_597832 != nil:
    section.add "MaxResults", valid_597832
  var valid_597833 = query.getOrDefault("Owner")
  valid_597833 = validateParameter(valid_597833, JArray, required = false,
                                 default = nil)
  if valid_597833 != nil:
    section.add "Owner", valid_597833
  var valid_597834 = query.getOrDefault("State")
  valid_597834 = validateParameter(valid_597834, JArray, required = false,
                                 default = nil)
  if valid_597834 != nil:
    section.add "State", valid_597834
  var valid_597835 = query.getOrDefault("NextToken")
  valid_597835 = validateParameter(valid_597835, JString, required = false,
                                 default = nil)
  if valid_597835 != nil:
    section.add "NextToken", valid_597835
  var valid_597836 = query.getOrDefault("ProviderType")
  valid_597836 = validateParameter(valid_597836, JArray, required = false,
                                 default = nil)
  if valid_597836 != nil:
    section.add "ProviderType", valid_597836
  var valid_597837 = query.getOrDefault("Name")
  valid_597837 = validateParameter(valid_597837, JArray, required = false,
                                 default = nil)
  if valid_597837 != nil:
    section.add "Name", valid_597837
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
  var valid_597838 = header.getOrDefault("X-Amz-Signature")
  valid_597838 = validateParameter(valid_597838, JString, required = false,
                                 default = nil)
  if valid_597838 != nil:
    section.add "X-Amz-Signature", valid_597838
  var valid_597839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597839 = validateParameter(valid_597839, JString, required = false,
                                 default = nil)
  if valid_597839 != nil:
    section.add "X-Amz-Content-Sha256", valid_597839
  var valid_597840 = header.getOrDefault("X-Amz-Date")
  valid_597840 = validateParameter(valid_597840, JString, required = false,
                                 default = nil)
  if valid_597840 != nil:
    section.add "X-Amz-Date", valid_597840
  var valid_597841 = header.getOrDefault("X-Amz-Credential")
  valid_597841 = validateParameter(valid_597841, JString, required = false,
                                 default = nil)
  if valid_597841 != nil:
    section.add "X-Amz-Credential", valid_597841
  var valid_597842 = header.getOrDefault("X-Amz-Security-Token")
  valid_597842 = validateParameter(valid_597842, JString, required = false,
                                 default = nil)
  if valid_597842 != nil:
    section.add "X-Amz-Security-Token", valid_597842
  var valid_597843 = header.getOrDefault("X-Amz-Algorithm")
  valid_597843 = validateParameter(valid_597843, JString, required = false,
                                 default = nil)
  if valid_597843 != nil:
    section.add "X-Amz-Algorithm", valid_597843
  var valid_597844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597844 = validateParameter(valid_597844, JString, required = false,
                                 default = nil)
  if valid_597844 != nil:
    section.add "X-Amz-SignedHeaders", valid_597844
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_597867: Call_ListRepositoryAssociations_597718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists repository associations. You can optionally filter on one or more of the following recommendation properties: provider types, states, names, and owners.
  ## 
  let valid = call_597867.validator(path, query, header, formData, body)
  let scheme = call_597867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597867.url(scheme.get, call_597867.host, call_597867.base,
                         call_597867.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597867, url, valid)

proc call*(call_597938: Call_ListRepositoryAssociations_597718;
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
  var query_597939 = newJObject()
  add(query_597939, "MaxResults", newJInt(MaxResults))
  if Owner != nil:
    query_597939.add "Owner", Owner
  if State != nil:
    query_597939.add "State", State
  add(query_597939, "NextToken", newJString(NextToken))
  if ProviderType != nil:
    query_597939.add "ProviderType", ProviderType
  if Name != nil:
    query_597939.add "Name", Name
  result = call_597938.call(nil, query_597939, nil, nil, nil)

var listRepositoryAssociations* = Call_ListRepositoryAssociations_597718(
    name: "listRepositoryAssociations", meth: HttpMethod.HttpGet,
    host: "codeguru-reviewer.amazonaws.com", route: "/associations",
    validator: validate_ListRepositoryAssociations_597719, base: "/",
    url: url_ListRepositoryAssociations_597720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRepositoryAssociation_597993 = ref object of OpenApiRestCall_597380
proc url_DescribeRepositoryAssociation_597995(protocol: Scheme; host: string;
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

proc validate_DescribeRepositoryAssociation_597994(path: JsonNode; query: JsonNode;
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
  var valid_598010 = path.getOrDefault("AssociationArn")
  valid_598010 = validateParameter(valid_598010, JString, required = true,
                                 default = nil)
  if valid_598010 != nil:
    section.add "AssociationArn", valid_598010
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
  var valid_598011 = header.getOrDefault("X-Amz-Signature")
  valid_598011 = validateParameter(valid_598011, JString, required = false,
                                 default = nil)
  if valid_598011 != nil:
    section.add "X-Amz-Signature", valid_598011
  var valid_598012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598012 = validateParameter(valid_598012, JString, required = false,
                                 default = nil)
  if valid_598012 != nil:
    section.add "X-Amz-Content-Sha256", valid_598012
  var valid_598013 = header.getOrDefault("X-Amz-Date")
  valid_598013 = validateParameter(valid_598013, JString, required = false,
                                 default = nil)
  if valid_598013 != nil:
    section.add "X-Amz-Date", valid_598013
  var valid_598014 = header.getOrDefault("X-Amz-Credential")
  valid_598014 = validateParameter(valid_598014, JString, required = false,
                                 default = nil)
  if valid_598014 != nil:
    section.add "X-Amz-Credential", valid_598014
  var valid_598015 = header.getOrDefault("X-Amz-Security-Token")
  valid_598015 = validateParameter(valid_598015, JString, required = false,
                                 default = nil)
  if valid_598015 != nil:
    section.add "X-Amz-Security-Token", valid_598015
  var valid_598016 = header.getOrDefault("X-Amz-Algorithm")
  valid_598016 = validateParameter(valid_598016, JString, required = false,
                                 default = nil)
  if valid_598016 != nil:
    section.add "X-Amz-Algorithm", valid_598016
  var valid_598017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598017 = validateParameter(valid_598017, JString, required = false,
                                 default = nil)
  if valid_598017 != nil:
    section.add "X-Amz-SignedHeaders", valid_598017
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598018: Call_DescribeRepositoryAssociation_597993; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a repository association.
  ## 
  let valid = call_598018.validator(path, query, header, formData, body)
  let scheme = call_598018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598018.url(scheme.get, call_598018.host, call_598018.base,
                         call_598018.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598018, url, valid)

proc call*(call_598019: Call_DescribeRepositoryAssociation_597993;
          AssociationArn: string): Recallable =
  ## describeRepositoryAssociation
  ## Describes a repository association.
  ##   AssociationArn: string (required)
  ##                 : The Amazon Resource Name (ARN) identifying the association.
  var path_598020 = newJObject()
  add(path_598020, "AssociationArn", newJString(AssociationArn))
  result = call_598019.call(path_598020, nil, nil, nil, nil)

var describeRepositoryAssociation* = Call_DescribeRepositoryAssociation_597993(
    name: "describeRepositoryAssociation", meth: HttpMethod.HttpGet,
    host: "codeguru-reviewer.amazonaws.com",
    route: "/associations/{AssociationArn}",
    validator: validate_DescribeRepositoryAssociation_597994, base: "/",
    url: url_DescribeRepositoryAssociation_597995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateRepository_598021 = ref object of OpenApiRestCall_597380
proc url_DisassociateRepository_598023(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateRepository_598022(path: JsonNode; query: JsonNode;
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
  var valid_598024 = path.getOrDefault("AssociationArn")
  valid_598024 = validateParameter(valid_598024, JString, required = true,
                                 default = nil)
  if valid_598024 != nil:
    section.add "AssociationArn", valid_598024
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
  var valid_598025 = header.getOrDefault("X-Amz-Signature")
  valid_598025 = validateParameter(valid_598025, JString, required = false,
                                 default = nil)
  if valid_598025 != nil:
    section.add "X-Amz-Signature", valid_598025
  var valid_598026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598026 = validateParameter(valid_598026, JString, required = false,
                                 default = nil)
  if valid_598026 != nil:
    section.add "X-Amz-Content-Sha256", valid_598026
  var valid_598027 = header.getOrDefault("X-Amz-Date")
  valid_598027 = validateParameter(valid_598027, JString, required = false,
                                 default = nil)
  if valid_598027 != nil:
    section.add "X-Amz-Date", valid_598027
  var valid_598028 = header.getOrDefault("X-Amz-Credential")
  valid_598028 = validateParameter(valid_598028, JString, required = false,
                                 default = nil)
  if valid_598028 != nil:
    section.add "X-Amz-Credential", valid_598028
  var valid_598029 = header.getOrDefault("X-Amz-Security-Token")
  valid_598029 = validateParameter(valid_598029, JString, required = false,
                                 default = nil)
  if valid_598029 != nil:
    section.add "X-Amz-Security-Token", valid_598029
  var valid_598030 = header.getOrDefault("X-Amz-Algorithm")
  valid_598030 = validateParameter(valid_598030, JString, required = false,
                                 default = nil)
  if valid_598030 != nil:
    section.add "X-Amz-Algorithm", valid_598030
  var valid_598031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598031 = validateParameter(valid_598031, JString, required = false,
                                 default = nil)
  if valid_598031 != nil:
    section.add "X-Amz-SignedHeaders", valid_598031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598032: Call_DisassociateRepository_598021; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the association between Amazon CodeGuru Reviewer and a repository.
  ## 
  let valid = call_598032.validator(path, query, header, formData, body)
  let scheme = call_598032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598032.url(scheme.get, call_598032.host, call_598032.base,
                         call_598032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598032, url, valid)

proc call*(call_598033: Call_DisassociateRepository_598021; AssociationArn: string): Recallable =
  ## disassociateRepository
  ## Removes the association between Amazon CodeGuru Reviewer and a repository.
  ##   AssociationArn: string (required)
  ##                 : The Amazon Resource Name (ARN) identifying the association.
  var path_598034 = newJObject()
  add(path_598034, "AssociationArn", newJString(AssociationArn))
  result = call_598033.call(path_598034, nil, nil, nil, nil)

var disassociateRepository* = Call_DisassociateRepository_598021(
    name: "disassociateRepository", meth: HttpMethod.HttpDelete,
    host: "codeguru-reviewer.amazonaws.com",
    route: "/associations/{AssociationArn}",
    validator: validate_DisassociateRepository_598022, base: "/",
    url: url_DisassociateRepository_598023, schemes: {Scheme.Https, Scheme.Http})
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
