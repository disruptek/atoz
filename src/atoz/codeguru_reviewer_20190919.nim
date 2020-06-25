
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625426): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AssociateRepository_21626014 = ref object of OpenApiRestCall_21625426
proc url_AssociateRepository_21626016(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateRepository_21626015(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Associates an AWS CodeCommit repository with Amazon CodeGuru Reviewer. When you associate an AWS CodeCommit repository with Amazon CodeGuru Reviewer, Amazon CodeGuru Reviewer will provide recommendations for each pull request. You can view recommendations in the AWS CodeCommit repository.</p> <p>You can associate a GitHub repository using the Amazon CodeGuru Reviewer console.</p>
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626017 = header.getOrDefault("X-Amz-Date")
  valid_21626017 = validateParameter(valid_21626017, JString, required = false,
                                   default = nil)
  if valid_21626017 != nil:
    section.add "X-Amz-Date", valid_21626017
  var valid_21626018 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626018 = validateParameter(valid_21626018, JString, required = false,
                                   default = nil)
  if valid_21626018 != nil:
    section.add "X-Amz-Security-Token", valid_21626018
  var valid_21626019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626019 = validateParameter(valid_21626019, JString, required = false,
                                   default = nil)
  if valid_21626019 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626019
  var valid_21626020 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626020 = validateParameter(valid_21626020, JString, required = false,
                                   default = nil)
  if valid_21626020 != nil:
    section.add "X-Amz-Algorithm", valid_21626020
  var valid_21626021 = header.getOrDefault("X-Amz-Signature")
  valid_21626021 = validateParameter(valid_21626021, JString, required = false,
                                   default = nil)
  if valid_21626021 != nil:
    section.add "X-Amz-Signature", valid_21626021
  var valid_21626022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626022 = validateParameter(valid_21626022, JString, required = false,
                                   default = nil)
  if valid_21626022 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626022
  var valid_21626023 = header.getOrDefault("X-Amz-Credential")
  valid_21626023 = validateParameter(valid_21626023, JString, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "X-Amz-Credential", valid_21626023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626025: Call_AssociateRepository_21626014; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Associates an AWS CodeCommit repository with Amazon CodeGuru Reviewer. When you associate an AWS CodeCommit repository with Amazon CodeGuru Reviewer, Amazon CodeGuru Reviewer will provide recommendations for each pull request. You can view recommendations in the AWS CodeCommit repository.</p> <p>You can associate a GitHub repository using the Amazon CodeGuru Reviewer console.</p>
  ## 
  let valid = call_21626025.validator(path, query, header, formData, body, _)
  let scheme = call_21626025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626025.makeUrl(scheme.get, call_21626025.host, call_21626025.base,
                               call_21626025.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626025, uri, valid, _)

proc call*(call_21626026: Call_AssociateRepository_21626014; body: JsonNode): Recallable =
  ## associateRepository
  ## <p>Associates an AWS CodeCommit repository with Amazon CodeGuru Reviewer. When you associate an AWS CodeCommit repository with Amazon CodeGuru Reviewer, Amazon CodeGuru Reviewer will provide recommendations for each pull request. You can view recommendations in the AWS CodeCommit repository.</p> <p>You can associate a GitHub repository using the Amazon CodeGuru Reviewer console.</p>
  ##   body: JObject (required)
  var body_21626027 = newJObject()
  if body != nil:
    body_21626027 = body
  result = call_21626026.call(nil, nil, nil, nil, body_21626027)

var associateRepository* = Call_AssociateRepository_21626014(
    name: "associateRepository", meth: HttpMethod.HttpPost,
    host: "codeguru-reviewer.amazonaws.com", route: "/associations",
    validator: validate_AssociateRepository_21626015, base: "/",
    makeUrl: url_AssociateRepository_21626016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRepositoryAssociations_21625770 = ref object of OpenApiRestCall_21625426
proc url_ListRepositoryAssociations_21625772(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRepositoryAssociations_21625771(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists repository associations. You can optionally filter on one or more of the following recommendation properties: provider types, states, names, and owners.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Owner: JArray
  ##        : List of owners to use as a filter. For AWS CodeCommit, the owner is the AWS account id. For GitHub, it is the GitHub account name.
  ##   ProviderType: JArray
  ##               : List of provider types to use as a filter.
  ##   Name: JArray
  ##       : List of names to use as a filter.
  ##   State: JArray
  ##        : List of states to use as a filter.
  ##   NextToken: JString
  ##            : <p>The <code>nextToken</code> value returned from a previous paginated <code>ListRepositoryAssociations</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value. </p> <note> <p>This token should be treated as an opaque identifier that is only used to retrieve the next items in a list and not for other programmatic purposes.</p> </note>
  ##   MaxResults: JInt
  ##             : The maximum number of repository association results returned by <code>ListRepositoryAssociations</code> in paginated output. When this parameter is used, <code>ListRepositoryAssociations</code> only returns <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. The remaining results of the initial request can be seen by sending another <code>ListRepositoryAssociations</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If this parameter is not used, then <code>ListRepositoryAssociations</code> returns up to 100 results and a <code>nextToken</code> value if applicable. 
  section = newJObject()
  var valid_21625873 = query.getOrDefault("Owner")
  valid_21625873 = validateParameter(valid_21625873, JArray, required = false,
                                   default = nil)
  if valid_21625873 != nil:
    section.add "Owner", valid_21625873
  var valid_21625874 = query.getOrDefault("ProviderType")
  valid_21625874 = validateParameter(valid_21625874, JArray, required = false,
                                   default = nil)
  if valid_21625874 != nil:
    section.add "ProviderType", valid_21625874
  var valid_21625875 = query.getOrDefault("Name")
  valid_21625875 = validateParameter(valid_21625875, JArray, required = false,
                                   default = nil)
  if valid_21625875 != nil:
    section.add "Name", valid_21625875
  var valid_21625876 = query.getOrDefault("State")
  valid_21625876 = validateParameter(valid_21625876, JArray, required = false,
                                   default = nil)
  if valid_21625876 != nil:
    section.add "State", valid_21625876
  var valid_21625877 = query.getOrDefault("NextToken")
  valid_21625877 = validateParameter(valid_21625877, JString, required = false,
                                   default = nil)
  if valid_21625877 != nil:
    section.add "NextToken", valid_21625877
  var valid_21625878 = query.getOrDefault("MaxResults")
  valid_21625878 = validateParameter(valid_21625878, JInt, required = false,
                                   default = nil)
  if valid_21625878 != nil:
    section.add "MaxResults", valid_21625878
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625879 = header.getOrDefault("X-Amz-Date")
  valid_21625879 = validateParameter(valid_21625879, JString, required = false,
                                   default = nil)
  if valid_21625879 != nil:
    section.add "X-Amz-Date", valid_21625879
  var valid_21625880 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625880 = validateParameter(valid_21625880, JString, required = false,
                                   default = nil)
  if valid_21625880 != nil:
    section.add "X-Amz-Security-Token", valid_21625880
  var valid_21625881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625881 = validateParameter(valid_21625881, JString, required = false,
                                   default = nil)
  if valid_21625881 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625881
  var valid_21625882 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "X-Amz-Algorithm", valid_21625882
  var valid_21625883 = header.getOrDefault("X-Amz-Signature")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Signature", valid_21625883
  var valid_21625884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-Credential")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-Credential", valid_21625885
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625910: Call_ListRepositoryAssociations_21625770;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists repository associations. You can optionally filter on one or more of the following recommendation properties: provider types, states, names, and owners.
  ## 
  let valid = call_21625910.validator(path, query, header, formData, body, _)
  let scheme = call_21625910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625910.makeUrl(scheme.get, call_21625910.host, call_21625910.base,
                               call_21625910.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625910, uri, valid, _)

proc call*(call_21625973: Call_ListRepositoryAssociations_21625770;
          Owner: JsonNode = nil; ProviderType: JsonNode = nil; Name: JsonNode = nil;
          State: JsonNode = nil; NextToken: string = ""; MaxResults: int = 0): Recallable =
  ## listRepositoryAssociations
  ## Lists repository associations. You can optionally filter on one or more of the following recommendation properties: provider types, states, names, and owners.
  ##   Owner: JArray
  ##        : List of owners to use as a filter. For AWS CodeCommit, the owner is the AWS account id. For GitHub, it is the GitHub account name.
  ##   ProviderType: JArray
  ##               : List of provider types to use as a filter.
  ##   Name: JArray
  ##       : List of names to use as a filter.
  ##   State: JArray
  ##        : List of states to use as a filter.
  ##   NextToken: string
  ##            : <p>The <code>nextToken</code> value returned from a previous paginated <code>ListRepositoryAssociations</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value. </p> <note> <p>This token should be treated as an opaque identifier that is only used to retrieve the next items in a list and not for other programmatic purposes.</p> </note>
  ##   MaxResults: int
  ##             : The maximum number of repository association results returned by <code>ListRepositoryAssociations</code> in paginated output. When this parameter is used, <code>ListRepositoryAssociations</code> only returns <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. The remaining results of the initial request can be seen by sending another <code>ListRepositoryAssociations</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If this parameter is not used, then <code>ListRepositoryAssociations</code> returns up to 100 results and a <code>nextToken</code> value if applicable. 
  var query_21625975 = newJObject()
  if Owner != nil:
    query_21625975.add "Owner", Owner
  if ProviderType != nil:
    query_21625975.add "ProviderType", ProviderType
  if Name != nil:
    query_21625975.add "Name", Name
  if State != nil:
    query_21625975.add "State", State
  add(query_21625975, "NextToken", newJString(NextToken))
  add(query_21625975, "MaxResults", newJInt(MaxResults))
  result = call_21625973.call(nil, query_21625975, nil, nil, nil)

var listRepositoryAssociations* = Call_ListRepositoryAssociations_21625770(
    name: "listRepositoryAssociations", meth: HttpMethod.HttpGet,
    host: "codeguru-reviewer.amazonaws.com", route: "/associations",
    validator: validate_ListRepositoryAssociations_21625771, base: "/",
    makeUrl: url_ListRepositoryAssociations_21625772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRepositoryAssociation_21626028 = ref object of OpenApiRestCall_21625426
proc url_DescribeRepositoryAssociation_21626030(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeRepositoryAssociation_21626029(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626044 = path.getOrDefault("AssociationArn")
  valid_21626044 = validateParameter(valid_21626044, JString, required = true,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "AssociationArn", valid_21626044
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626045 = header.getOrDefault("X-Amz-Date")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Date", valid_21626045
  var valid_21626046 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-Security-Token", valid_21626046
  var valid_21626047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Algorithm", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Signature")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Signature", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Credential")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Credential", valid_21626051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626052: Call_DescribeRepositoryAssociation_21626028;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a repository association.
  ## 
  let valid = call_21626052.validator(path, query, header, formData, body, _)
  let scheme = call_21626052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626052.makeUrl(scheme.get, call_21626052.host, call_21626052.base,
                               call_21626052.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626052, uri, valid, _)

proc call*(call_21626053: Call_DescribeRepositoryAssociation_21626028;
          AssociationArn: string): Recallable =
  ## describeRepositoryAssociation
  ## Describes a repository association.
  ##   AssociationArn: string (required)
  ##                 : The Amazon Resource Name (ARN) identifying the association.
  var path_21626054 = newJObject()
  add(path_21626054, "AssociationArn", newJString(AssociationArn))
  result = call_21626053.call(path_21626054, nil, nil, nil, nil)

var describeRepositoryAssociation* = Call_DescribeRepositoryAssociation_21626028(
    name: "describeRepositoryAssociation", meth: HttpMethod.HttpGet,
    host: "codeguru-reviewer.amazonaws.com",
    route: "/associations/{AssociationArn}",
    validator: validate_DescribeRepositoryAssociation_21626029, base: "/",
    makeUrl: url_DescribeRepositoryAssociation_21626030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateRepository_21626055 = ref object of OpenApiRestCall_21625426
proc url_DisassociateRepository_21626057(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateRepository_21626056(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626058 = path.getOrDefault("AssociationArn")
  valid_21626058 = validateParameter(valid_21626058, JString, required = true,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "AssociationArn", valid_21626058
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626059 = header.getOrDefault("X-Amz-Date")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Date", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Security-Token", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Algorithm", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Signature")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Signature", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Credential")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Credential", valid_21626065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626066: Call_DisassociateRepository_21626055;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the association between Amazon CodeGuru Reviewer and a repository.
  ## 
  let valid = call_21626066.validator(path, query, header, formData, body, _)
  let scheme = call_21626066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626066.makeUrl(scheme.get, call_21626066.host, call_21626066.base,
                               call_21626066.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626066, uri, valid, _)

proc call*(call_21626067: Call_DisassociateRepository_21626055;
          AssociationArn: string): Recallable =
  ## disassociateRepository
  ## Removes the association between Amazon CodeGuru Reviewer and a repository.
  ##   AssociationArn: string (required)
  ##                 : The Amazon Resource Name (ARN) identifying the association.
  var path_21626068 = newJObject()
  add(path_21626068, "AssociationArn", newJString(AssociationArn))
  result = call_21626067.call(path_21626068, nil, nil, nil, nil)

var disassociateRepository* = Call_DisassociateRepository_21626055(
    name: "disassociateRepository", meth: HttpMethod.HttpDelete,
    host: "codeguru-reviewer.amazonaws.com",
    route: "/associations/{AssociationArn}",
    validator: validate_DisassociateRepository_21626056, base: "/",
    makeUrl: url_DisassociateRepository_21626057,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}