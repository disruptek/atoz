
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

  OpenApiRestCall_605580 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605580](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605580): Option[Scheme] {.used.} =
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
  Call_AssociateRepository_606179 = ref object of OpenApiRestCall_605580
proc url_AssociateRepository_606181(protocol: Scheme; host: string; base: string;
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

proc validate_AssociateRepository_606180(path: JsonNode; query: JsonNode;
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
  var valid_606182 = header.getOrDefault("X-Amz-Signature")
  valid_606182 = validateParameter(valid_606182, JString, required = false,
                                 default = nil)
  if valid_606182 != nil:
    section.add "X-Amz-Signature", valid_606182
  var valid_606183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606183 = validateParameter(valid_606183, JString, required = false,
                                 default = nil)
  if valid_606183 != nil:
    section.add "X-Amz-Content-Sha256", valid_606183
  var valid_606184 = header.getOrDefault("X-Amz-Date")
  valid_606184 = validateParameter(valid_606184, JString, required = false,
                                 default = nil)
  if valid_606184 != nil:
    section.add "X-Amz-Date", valid_606184
  var valid_606185 = header.getOrDefault("X-Amz-Credential")
  valid_606185 = validateParameter(valid_606185, JString, required = false,
                                 default = nil)
  if valid_606185 != nil:
    section.add "X-Amz-Credential", valid_606185
  var valid_606186 = header.getOrDefault("X-Amz-Security-Token")
  valid_606186 = validateParameter(valid_606186, JString, required = false,
                                 default = nil)
  if valid_606186 != nil:
    section.add "X-Amz-Security-Token", valid_606186
  var valid_606187 = header.getOrDefault("X-Amz-Algorithm")
  valid_606187 = validateParameter(valid_606187, JString, required = false,
                                 default = nil)
  if valid_606187 != nil:
    section.add "X-Amz-Algorithm", valid_606187
  var valid_606188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606188 = validateParameter(valid_606188, JString, required = false,
                                 default = nil)
  if valid_606188 != nil:
    section.add "X-Amz-SignedHeaders", valid_606188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606190: Call_AssociateRepository_606179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates an AWS CodeCommit repository with Amazon CodeGuru Reviewer. When you associate an AWS CodeCommit repository with Amazon CodeGuru Reviewer, Amazon CodeGuru Reviewer will provide recommendations for each pull request. You can view recommendations in the AWS CodeCommit repository.</p> <p>You can associate a GitHub repository using the Amazon CodeGuru Reviewer console.</p>
  ## 
  let valid = call_606190.validator(path, query, header, formData, body)
  let scheme = call_606190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606190.url(scheme.get, call_606190.host, call_606190.base,
                         call_606190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606190, url, valid)

proc call*(call_606191: Call_AssociateRepository_606179; body: JsonNode): Recallable =
  ## associateRepository
  ## <p>Associates an AWS CodeCommit repository with Amazon CodeGuru Reviewer. When you associate an AWS CodeCommit repository with Amazon CodeGuru Reviewer, Amazon CodeGuru Reviewer will provide recommendations for each pull request. You can view recommendations in the AWS CodeCommit repository.</p> <p>You can associate a GitHub repository using the Amazon CodeGuru Reviewer console.</p>
  ##   body: JObject (required)
  var body_606192 = newJObject()
  if body != nil:
    body_606192 = body
  result = call_606191.call(nil, nil, nil, nil, body_606192)

var associateRepository* = Call_AssociateRepository_606179(
    name: "associateRepository", meth: HttpMethod.HttpPost,
    host: "codeguru-reviewer.amazonaws.com", route: "/associations",
    validator: validate_AssociateRepository_606180, base: "/",
    url: url_AssociateRepository_606181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRepositoryAssociations_605918 = ref object of OpenApiRestCall_605580
proc url_ListRepositoryAssociations_605920(protocol: Scheme; host: string;
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

proc validate_ListRepositoryAssociations_605919(path: JsonNode; query: JsonNode;
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
  var valid_606032 = query.getOrDefault("MaxResults")
  valid_606032 = validateParameter(valid_606032, JInt, required = false, default = nil)
  if valid_606032 != nil:
    section.add "MaxResults", valid_606032
  var valid_606033 = query.getOrDefault("Owner")
  valid_606033 = validateParameter(valid_606033, JArray, required = false,
                                 default = nil)
  if valid_606033 != nil:
    section.add "Owner", valid_606033
  var valid_606034 = query.getOrDefault("State")
  valid_606034 = validateParameter(valid_606034, JArray, required = false,
                                 default = nil)
  if valid_606034 != nil:
    section.add "State", valid_606034
  var valid_606035 = query.getOrDefault("NextToken")
  valid_606035 = validateParameter(valid_606035, JString, required = false,
                                 default = nil)
  if valid_606035 != nil:
    section.add "NextToken", valid_606035
  var valid_606036 = query.getOrDefault("ProviderType")
  valid_606036 = validateParameter(valid_606036, JArray, required = false,
                                 default = nil)
  if valid_606036 != nil:
    section.add "ProviderType", valid_606036
  var valid_606037 = query.getOrDefault("Name")
  valid_606037 = validateParameter(valid_606037, JArray, required = false,
                                 default = nil)
  if valid_606037 != nil:
    section.add "Name", valid_606037
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
  var valid_606038 = header.getOrDefault("X-Amz-Signature")
  valid_606038 = validateParameter(valid_606038, JString, required = false,
                                 default = nil)
  if valid_606038 != nil:
    section.add "X-Amz-Signature", valid_606038
  var valid_606039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606039 = validateParameter(valid_606039, JString, required = false,
                                 default = nil)
  if valid_606039 != nil:
    section.add "X-Amz-Content-Sha256", valid_606039
  var valid_606040 = header.getOrDefault("X-Amz-Date")
  valid_606040 = validateParameter(valid_606040, JString, required = false,
                                 default = nil)
  if valid_606040 != nil:
    section.add "X-Amz-Date", valid_606040
  var valid_606041 = header.getOrDefault("X-Amz-Credential")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "X-Amz-Credential", valid_606041
  var valid_606042 = header.getOrDefault("X-Amz-Security-Token")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "X-Amz-Security-Token", valid_606042
  var valid_606043 = header.getOrDefault("X-Amz-Algorithm")
  valid_606043 = validateParameter(valid_606043, JString, required = false,
                                 default = nil)
  if valid_606043 != nil:
    section.add "X-Amz-Algorithm", valid_606043
  var valid_606044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606044 = validateParameter(valid_606044, JString, required = false,
                                 default = nil)
  if valid_606044 != nil:
    section.add "X-Amz-SignedHeaders", valid_606044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606067: Call_ListRepositoryAssociations_605918; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists repository associations. You can optionally filter on one or more of the following recommendation properties: provider types, states, names, and owners.
  ## 
  let valid = call_606067.validator(path, query, header, formData, body)
  let scheme = call_606067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606067.url(scheme.get, call_606067.host, call_606067.base,
                         call_606067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606067, url, valid)

proc call*(call_606138: Call_ListRepositoryAssociations_605918;
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
  var query_606139 = newJObject()
  add(query_606139, "MaxResults", newJInt(MaxResults))
  if Owner != nil:
    query_606139.add "Owner", Owner
  if State != nil:
    query_606139.add "State", State
  add(query_606139, "NextToken", newJString(NextToken))
  if ProviderType != nil:
    query_606139.add "ProviderType", ProviderType
  if Name != nil:
    query_606139.add "Name", Name
  result = call_606138.call(nil, query_606139, nil, nil, nil)

var listRepositoryAssociations* = Call_ListRepositoryAssociations_605918(
    name: "listRepositoryAssociations", meth: HttpMethod.HttpGet,
    host: "codeguru-reviewer.amazonaws.com", route: "/associations",
    validator: validate_ListRepositoryAssociations_605919, base: "/",
    url: url_ListRepositoryAssociations_605920,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRepositoryAssociation_606193 = ref object of OpenApiRestCall_605580
proc url_DescribeRepositoryAssociation_606195(protocol: Scheme; host: string;
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

proc validate_DescribeRepositoryAssociation_606194(path: JsonNode; query: JsonNode;
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
  var valid_606210 = path.getOrDefault("AssociationArn")
  valid_606210 = validateParameter(valid_606210, JString, required = true,
                                 default = nil)
  if valid_606210 != nil:
    section.add "AssociationArn", valid_606210
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
  var valid_606211 = header.getOrDefault("X-Amz-Signature")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-Signature", valid_606211
  var valid_606212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "X-Amz-Content-Sha256", valid_606212
  var valid_606213 = header.getOrDefault("X-Amz-Date")
  valid_606213 = validateParameter(valid_606213, JString, required = false,
                                 default = nil)
  if valid_606213 != nil:
    section.add "X-Amz-Date", valid_606213
  var valid_606214 = header.getOrDefault("X-Amz-Credential")
  valid_606214 = validateParameter(valid_606214, JString, required = false,
                                 default = nil)
  if valid_606214 != nil:
    section.add "X-Amz-Credential", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Security-Token")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Security-Token", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Algorithm")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Algorithm", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-SignedHeaders", valid_606217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606218: Call_DescribeRepositoryAssociation_606193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a repository association.
  ## 
  let valid = call_606218.validator(path, query, header, formData, body)
  let scheme = call_606218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606218.url(scheme.get, call_606218.host, call_606218.base,
                         call_606218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606218, url, valid)

proc call*(call_606219: Call_DescribeRepositoryAssociation_606193;
          AssociationArn: string): Recallable =
  ## describeRepositoryAssociation
  ## Describes a repository association.
  ##   AssociationArn: string (required)
  ##                 : The Amazon Resource Name (ARN) identifying the association.
  var path_606220 = newJObject()
  add(path_606220, "AssociationArn", newJString(AssociationArn))
  result = call_606219.call(path_606220, nil, nil, nil, nil)

var describeRepositoryAssociation* = Call_DescribeRepositoryAssociation_606193(
    name: "describeRepositoryAssociation", meth: HttpMethod.HttpGet,
    host: "codeguru-reviewer.amazonaws.com",
    route: "/associations/{AssociationArn}",
    validator: validate_DescribeRepositoryAssociation_606194, base: "/",
    url: url_DescribeRepositoryAssociation_606195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateRepository_606221 = ref object of OpenApiRestCall_605580
proc url_DisassociateRepository_606223(protocol: Scheme; host: string; base: string;
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

proc validate_DisassociateRepository_606222(path: JsonNode; query: JsonNode;
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
  var valid_606224 = path.getOrDefault("AssociationArn")
  valid_606224 = validateParameter(valid_606224, JString, required = true,
                                 default = nil)
  if valid_606224 != nil:
    section.add "AssociationArn", valid_606224
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
  var valid_606225 = header.getOrDefault("X-Amz-Signature")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Signature", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Content-Sha256", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Date")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Date", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Credential")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Credential", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-Security-Token")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-Security-Token", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Algorithm")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Algorithm", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-SignedHeaders", valid_606231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606232: Call_DisassociateRepository_606221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the association between Amazon CodeGuru Reviewer and a repository.
  ## 
  let valid = call_606232.validator(path, query, header, formData, body)
  let scheme = call_606232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606232.url(scheme.get, call_606232.host, call_606232.base,
                         call_606232.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606232, url, valid)

proc call*(call_606233: Call_DisassociateRepository_606221; AssociationArn: string): Recallable =
  ## disassociateRepository
  ## Removes the association between Amazon CodeGuru Reviewer and a repository.
  ##   AssociationArn: string (required)
  ##                 : The Amazon Resource Name (ARN) identifying the association.
  var path_606234 = newJObject()
  add(path_606234, "AssociationArn", newJString(AssociationArn))
  result = call_606233.call(path_606234, nil, nil, nil, nil)

var disassociateRepository* = Call_DisassociateRepository_606221(
    name: "disassociateRepository", meth: HttpMethod.HttpDelete,
    host: "codeguru-reviewer.amazonaws.com",
    route: "/associations/{AssociationArn}",
    validator: validate_DisassociateRepository_606222, base: "/",
    url: url_DisassociateRepository_606223, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
