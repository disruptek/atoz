
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon QLDB
## version: 2019-01-02
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## The control plane for Amazon QLDB
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/qldb/
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "qldb.ap-northeast-1.amazonaws.com", "ap-southeast-1": "qldb.ap-southeast-1.amazonaws.com",
                           "us-west-2": "qldb.us-west-2.amazonaws.com",
                           "eu-west-2": "qldb.eu-west-2.amazonaws.com", "ap-northeast-3": "qldb.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "qldb.eu-central-1.amazonaws.com",
                           "us-east-2": "qldb.us-east-2.amazonaws.com",
                           "us-east-1": "qldb.us-east-1.amazonaws.com", "cn-northwest-1": "qldb.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "qldb.ap-south-1.amazonaws.com",
                           "eu-north-1": "qldb.eu-north-1.amazonaws.com", "ap-northeast-2": "qldb.ap-northeast-2.amazonaws.com",
                           "us-west-1": "qldb.us-west-1.amazonaws.com",
                           "us-gov-east-1": "qldb.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "qldb.eu-west-3.amazonaws.com",
                           "cn-north-1": "qldb.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "qldb.sa-east-1.amazonaws.com",
                           "eu-west-1": "qldb.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "qldb.us-gov-west-1.amazonaws.com", "ap-southeast-2": "qldb.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "qldb.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "qldb.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "qldb.ap-southeast-1.amazonaws.com",
      "us-west-2": "qldb.us-west-2.amazonaws.com",
      "eu-west-2": "qldb.eu-west-2.amazonaws.com",
      "ap-northeast-3": "qldb.ap-northeast-3.amazonaws.com",
      "eu-central-1": "qldb.eu-central-1.amazonaws.com",
      "us-east-2": "qldb.us-east-2.amazonaws.com",
      "us-east-1": "qldb.us-east-1.amazonaws.com",
      "cn-northwest-1": "qldb.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "qldb.ap-south-1.amazonaws.com",
      "eu-north-1": "qldb.eu-north-1.amazonaws.com",
      "ap-northeast-2": "qldb.ap-northeast-2.amazonaws.com",
      "us-west-1": "qldb.us-west-1.amazonaws.com",
      "us-gov-east-1": "qldb.us-gov-east-1.amazonaws.com",
      "eu-west-3": "qldb.eu-west-3.amazonaws.com",
      "cn-north-1": "qldb.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "qldb.sa-east-1.amazonaws.com",
      "eu-west-1": "qldb.eu-west-1.amazonaws.com",
      "us-gov-west-1": "qldb.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "qldb.ap-southeast-2.amazonaws.com",
      "ca-central-1": "qldb.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "qldb"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateLedger_611255 = ref object of OpenApiRestCall_610658
proc url_CreateLedger_611257(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLedger_611256(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new ledger in your AWS account.
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
  var valid_611258 = header.getOrDefault("X-Amz-Signature")
  valid_611258 = validateParameter(valid_611258, JString, required = false,
                                 default = nil)
  if valid_611258 != nil:
    section.add "X-Amz-Signature", valid_611258
  var valid_611259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611259 = validateParameter(valid_611259, JString, required = false,
                                 default = nil)
  if valid_611259 != nil:
    section.add "X-Amz-Content-Sha256", valid_611259
  var valid_611260 = header.getOrDefault("X-Amz-Date")
  valid_611260 = validateParameter(valid_611260, JString, required = false,
                                 default = nil)
  if valid_611260 != nil:
    section.add "X-Amz-Date", valid_611260
  var valid_611261 = header.getOrDefault("X-Amz-Credential")
  valid_611261 = validateParameter(valid_611261, JString, required = false,
                                 default = nil)
  if valid_611261 != nil:
    section.add "X-Amz-Credential", valid_611261
  var valid_611262 = header.getOrDefault("X-Amz-Security-Token")
  valid_611262 = validateParameter(valid_611262, JString, required = false,
                                 default = nil)
  if valid_611262 != nil:
    section.add "X-Amz-Security-Token", valid_611262
  var valid_611263 = header.getOrDefault("X-Amz-Algorithm")
  valid_611263 = validateParameter(valid_611263, JString, required = false,
                                 default = nil)
  if valid_611263 != nil:
    section.add "X-Amz-Algorithm", valid_611263
  var valid_611264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611264 = validateParameter(valid_611264, JString, required = false,
                                 default = nil)
  if valid_611264 != nil:
    section.add "X-Amz-SignedHeaders", valid_611264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611266: Call_CreateLedger_611255; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new ledger in your AWS account.
  ## 
  let valid = call_611266.validator(path, query, header, formData, body)
  let scheme = call_611266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611266.url(scheme.get, call_611266.host, call_611266.base,
                         call_611266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611266, url, valid)

proc call*(call_611267: Call_CreateLedger_611255; body: JsonNode): Recallable =
  ## createLedger
  ## Creates a new ledger in your AWS account.
  ##   body: JObject (required)
  var body_611268 = newJObject()
  if body != nil:
    body_611268 = body
  result = call_611267.call(nil, nil, nil, nil, body_611268)

var createLedger* = Call_CreateLedger_611255(name: "createLedger",
    meth: HttpMethod.HttpPost, host: "qldb.amazonaws.com", route: "/ledgers",
    validator: validate_CreateLedger_611256, base: "/", url: url_CreateLedger_611257,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLedgers_610996 = ref object of OpenApiRestCall_610658
proc url_ListLedgers_610998(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLedgers_610997(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns an array of ledger summaries that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of 100 items and is paginated so that you can retrieve all the items by calling <code>ListLedgers</code> multiple times.</p>
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
  ##   next_token: JString
  ##             : A pagination token, indicating that you want to retrieve the next page of results. If you received a value for <code>NextToken</code> in the response from a previous <code>ListLedgers</code> call, then you should use that value as input here.
  ##   max_results: JInt
  ##              : The maximum number of results to return in a single <code>ListLedgers</code> request. (The actual number of results returned might be fewer.)
  section = newJObject()
  var valid_611110 = query.getOrDefault("MaxResults")
  valid_611110 = validateParameter(valid_611110, JString, required = false,
                                 default = nil)
  if valid_611110 != nil:
    section.add "MaxResults", valid_611110
  var valid_611111 = query.getOrDefault("NextToken")
  valid_611111 = validateParameter(valid_611111, JString, required = false,
                                 default = nil)
  if valid_611111 != nil:
    section.add "NextToken", valid_611111
  var valid_611112 = query.getOrDefault("next_token")
  valid_611112 = validateParameter(valid_611112, JString, required = false,
                                 default = nil)
  if valid_611112 != nil:
    section.add "next_token", valid_611112
  var valid_611113 = query.getOrDefault("max_results")
  valid_611113 = validateParameter(valid_611113, JInt, required = false, default = nil)
  if valid_611113 != nil:
    section.add "max_results", valid_611113
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
  var valid_611114 = header.getOrDefault("X-Amz-Signature")
  valid_611114 = validateParameter(valid_611114, JString, required = false,
                                 default = nil)
  if valid_611114 != nil:
    section.add "X-Amz-Signature", valid_611114
  var valid_611115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611115 = validateParameter(valid_611115, JString, required = false,
                                 default = nil)
  if valid_611115 != nil:
    section.add "X-Amz-Content-Sha256", valid_611115
  var valid_611116 = header.getOrDefault("X-Amz-Date")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-Date", valid_611116
  var valid_611117 = header.getOrDefault("X-Amz-Credential")
  valid_611117 = validateParameter(valid_611117, JString, required = false,
                                 default = nil)
  if valid_611117 != nil:
    section.add "X-Amz-Credential", valid_611117
  var valid_611118 = header.getOrDefault("X-Amz-Security-Token")
  valid_611118 = validateParameter(valid_611118, JString, required = false,
                                 default = nil)
  if valid_611118 != nil:
    section.add "X-Amz-Security-Token", valid_611118
  var valid_611119 = header.getOrDefault("X-Amz-Algorithm")
  valid_611119 = validateParameter(valid_611119, JString, required = false,
                                 default = nil)
  if valid_611119 != nil:
    section.add "X-Amz-Algorithm", valid_611119
  var valid_611120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611120 = validateParameter(valid_611120, JString, required = false,
                                 default = nil)
  if valid_611120 != nil:
    section.add "X-Amz-SignedHeaders", valid_611120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611143: Call_ListLedgers_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an array of ledger summaries that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of 100 items and is paginated so that you can retrieve all the items by calling <code>ListLedgers</code> multiple times.</p>
  ## 
  let valid = call_611143.validator(path, query, header, formData, body)
  let scheme = call_611143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611143.url(scheme.get, call_611143.host, call_611143.base,
                         call_611143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611143, url, valid)

proc call*(call_611214: Call_ListLedgers_610996; MaxResults: string = "";
          NextToken: string = ""; nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listLedgers
  ## <p>Returns an array of ledger summaries that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of 100 items and is paginated so that you can retrieve all the items by calling <code>ListLedgers</code> multiple times.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##            : A pagination token, indicating that you want to retrieve the next page of results. If you received a value for <code>NextToken</code> in the response from a previous <code>ListLedgers</code> call, then you should use that value as input here.
  ##   maxResults: int
  ##             : The maximum number of results to return in a single <code>ListLedgers</code> request. (The actual number of results returned might be fewer.)
  var query_611215 = newJObject()
  add(query_611215, "MaxResults", newJString(MaxResults))
  add(query_611215, "NextToken", newJString(NextToken))
  add(query_611215, "next_token", newJString(nextToken))
  add(query_611215, "max_results", newJInt(maxResults))
  result = call_611214.call(nil, query_611215, nil, nil, nil)

var listLedgers* = Call_ListLedgers_610996(name: "listLedgers",
                                        meth: HttpMethod.HttpGet,
                                        host: "qldb.amazonaws.com",
                                        route: "/ledgers",
                                        validator: validate_ListLedgers_610997,
                                        base: "/", url: url_ListLedgers_610998,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLedger_611269 = ref object of OpenApiRestCall_610658
proc url_DescribeLedger_611271(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeLedger_611270(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns information about a ledger, including its state and when it was created.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the ledger that you want to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_611286 = path.getOrDefault("name")
  valid_611286 = validateParameter(valid_611286, JString, required = true,
                                 default = nil)
  if valid_611286 != nil:
    section.add "name", valid_611286
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
  var valid_611287 = header.getOrDefault("X-Amz-Signature")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Signature", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Content-Sha256", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Date")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Date", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-Credential")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Credential", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-Security-Token")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Security-Token", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-Algorithm")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Algorithm", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-SignedHeaders", valid_611293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611294: Call_DescribeLedger_611269; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a ledger, including its state and when it was created.
  ## 
  let valid = call_611294.validator(path, query, header, formData, body)
  let scheme = call_611294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611294.url(scheme.get, call_611294.host, call_611294.base,
                         call_611294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611294, url, valid)

proc call*(call_611295: Call_DescribeLedger_611269; name: string): Recallable =
  ## describeLedger
  ## Returns information about a ledger, including its state and when it was created.
  ##   name: string (required)
  ##       : The name of the ledger that you want to describe.
  var path_611296 = newJObject()
  add(path_611296, "name", newJString(name))
  result = call_611295.call(path_611296, nil, nil, nil, nil)

var describeLedger* = Call_DescribeLedger_611269(name: "describeLedger",
    meth: HttpMethod.HttpGet, host: "qldb.amazonaws.com", route: "/ledgers/{name}",
    validator: validate_DescribeLedger_611270, base: "/", url: url_DescribeLedger_611271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLedger_611311 = ref object of OpenApiRestCall_610658
proc url_UpdateLedger_611313(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateLedger_611312(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates properties on a ledger.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the ledger.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_611314 = path.getOrDefault("name")
  valid_611314 = validateParameter(valid_611314, JString, required = true,
                                 default = nil)
  if valid_611314 != nil:
    section.add "name", valid_611314
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
  var valid_611315 = header.getOrDefault("X-Amz-Signature")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Signature", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Content-Sha256", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Date")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Date", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Credential")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Credential", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Security-Token")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Security-Token", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-Algorithm")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-Algorithm", valid_611320
  var valid_611321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-SignedHeaders", valid_611321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611323: Call_UpdateLedger_611311; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates properties on a ledger.
  ## 
  let valid = call_611323.validator(path, query, header, formData, body)
  let scheme = call_611323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611323.url(scheme.get, call_611323.host, call_611323.base,
                         call_611323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611323, url, valid)

proc call*(call_611324: Call_UpdateLedger_611311; name: string; body: JsonNode): Recallable =
  ## updateLedger
  ## Updates properties on a ledger.
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_611325 = newJObject()
  var body_611326 = newJObject()
  add(path_611325, "name", newJString(name))
  if body != nil:
    body_611326 = body
  result = call_611324.call(path_611325, nil, nil, nil, body_611326)

var updateLedger* = Call_UpdateLedger_611311(name: "updateLedger",
    meth: HttpMethod.HttpPatch, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}", validator: validate_UpdateLedger_611312, base: "/",
    url: url_UpdateLedger_611313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLedger_611297 = ref object of OpenApiRestCall_610658
proc url_DeleteLedger_611299(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteLedger_611298(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a ledger and all of its contents. This action is irreversible.</p> <p>If deletion protection is enabled, you must first disable it before you can delete the ledger using the QLDB API or the AWS Command Line Interface (AWS CLI). You can disable it by calling the <code>UpdateLedger</code> operation to set the flag to <code>false</code>. The QLDB console disables deletion protection for you when you use it to delete a ledger.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the ledger that you want to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_611300 = path.getOrDefault("name")
  valid_611300 = validateParameter(valid_611300, JString, required = true,
                                 default = nil)
  if valid_611300 != nil:
    section.add "name", valid_611300
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
  var valid_611301 = header.getOrDefault("X-Amz-Signature")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Signature", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Content-Sha256", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Date")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Date", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Credential")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Credential", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-Security-Token")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-Security-Token", valid_611305
  var valid_611306 = header.getOrDefault("X-Amz-Algorithm")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "X-Amz-Algorithm", valid_611306
  var valid_611307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-SignedHeaders", valid_611307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611308: Call_DeleteLedger_611297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a ledger and all of its contents. This action is irreversible.</p> <p>If deletion protection is enabled, you must first disable it before you can delete the ledger using the QLDB API or the AWS Command Line Interface (AWS CLI). You can disable it by calling the <code>UpdateLedger</code> operation to set the flag to <code>false</code>. The QLDB console disables deletion protection for you when you use it to delete a ledger.</p>
  ## 
  let valid = call_611308.validator(path, query, header, formData, body)
  let scheme = call_611308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611308.url(scheme.get, call_611308.host, call_611308.base,
                         call_611308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611308, url, valid)

proc call*(call_611309: Call_DeleteLedger_611297; name: string): Recallable =
  ## deleteLedger
  ## <p>Deletes a ledger and all of its contents. This action is irreversible.</p> <p>If deletion protection is enabled, you must first disable it before you can delete the ledger using the QLDB API or the AWS Command Line Interface (AWS CLI). You can disable it by calling the <code>UpdateLedger</code> operation to set the flag to <code>false</code>. The QLDB console disables deletion protection for you when you use it to delete a ledger.</p>
  ##   name: string (required)
  ##       : The name of the ledger that you want to delete.
  var path_611310 = newJObject()
  add(path_611310, "name", newJString(name))
  result = call_611309.call(path_611310, nil, nil, nil, nil)

var deleteLedger* = Call_DeleteLedger_611297(name: "deleteLedger",
    meth: HttpMethod.HttpDelete, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}", validator: validate_DeleteLedger_611298, base: "/",
    url: url_DeleteLedger_611299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJournalS3Export_611327 = ref object of OpenApiRestCall_610658
proc url_DescribeJournalS3Export_611329(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  assert "exportId" in path, "`exportId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/journal-s3-exports/"),
               (kind: VariableSegment, value: "exportId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeJournalS3Export_611328(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about a journal export job, including the ledger name, export ID, when it was created, current status, and its start and end time export parameters.</p> <p>If the export job with the given <code>ExportId</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   exportId: JString (required)
  ##           : The unique ID of the journal export job that you want to describe.
  ##   name: JString (required)
  ##       : The name of the ledger.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `exportId` field"
  var valid_611330 = path.getOrDefault("exportId")
  valid_611330 = validateParameter(valid_611330, JString, required = true,
                                 default = nil)
  if valid_611330 != nil:
    section.add "exportId", valid_611330
  var valid_611331 = path.getOrDefault("name")
  valid_611331 = validateParameter(valid_611331, JString, required = true,
                                 default = nil)
  if valid_611331 != nil:
    section.add "name", valid_611331
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
  var valid_611332 = header.getOrDefault("X-Amz-Signature")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Signature", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Content-Sha256", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Date")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Date", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-Credential")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-Credential", valid_611335
  var valid_611336 = header.getOrDefault("X-Amz-Security-Token")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-Security-Token", valid_611336
  var valid_611337 = header.getOrDefault("X-Amz-Algorithm")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Algorithm", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-SignedHeaders", valid_611338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611339: Call_DescribeJournalS3Export_611327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a journal export job, including the ledger name, export ID, when it was created, current status, and its start and end time export parameters.</p> <p>If the export job with the given <code>ExportId</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p>
  ## 
  let valid = call_611339.validator(path, query, header, formData, body)
  let scheme = call_611339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611339.url(scheme.get, call_611339.host, call_611339.base,
                         call_611339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611339, url, valid)

proc call*(call_611340: Call_DescribeJournalS3Export_611327; exportId: string;
          name: string): Recallable =
  ## describeJournalS3Export
  ## <p>Returns information about a journal export job, including the ledger name, export ID, when it was created, current status, and its start and end time export parameters.</p> <p>If the export job with the given <code>ExportId</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p>
  ##   exportId: string (required)
  ##           : The unique ID of the journal export job that you want to describe.
  ##   name: string (required)
  ##       : The name of the ledger.
  var path_611341 = newJObject()
  add(path_611341, "exportId", newJString(exportId))
  add(path_611341, "name", newJString(name))
  result = call_611340.call(path_611341, nil, nil, nil, nil)

var describeJournalS3Export* = Call_DescribeJournalS3Export_611327(
    name: "describeJournalS3Export", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com",
    route: "/ledgers/{name}/journal-s3-exports/{exportId}",
    validator: validate_DescribeJournalS3Export_611328, base: "/",
    url: url_DescribeJournalS3Export_611329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportJournalToS3_611361 = ref object of OpenApiRestCall_610658
proc url_ExportJournalToS3_611363(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/journal-s3-exports")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ExportJournalToS3_611362(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Exports journal contents within a date and time range from a ledger into a specified Amazon Simple Storage Service (Amazon S3) bucket. The data is written as files in Amazon Ion format.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>You can initiate up to two concurrent journal export requests for each ledger. Beyond this limit, journal export requests throw <code>LimitExceededException</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the ledger.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_611364 = path.getOrDefault("name")
  valid_611364 = validateParameter(valid_611364, JString, required = true,
                                 default = nil)
  if valid_611364 != nil:
    section.add "name", valid_611364
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
  var valid_611365 = header.getOrDefault("X-Amz-Signature")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-Signature", valid_611365
  var valid_611366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "X-Amz-Content-Sha256", valid_611366
  var valid_611367 = header.getOrDefault("X-Amz-Date")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Date", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-Credential")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Credential", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-Security-Token")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Security-Token", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-Algorithm")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Algorithm", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-SignedHeaders", valid_611371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611373: Call_ExportJournalToS3_611361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Exports journal contents within a date and time range from a ledger into a specified Amazon Simple Storage Service (Amazon S3) bucket. The data is written as files in Amazon Ion format.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>You can initiate up to two concurrent journal export requests for each ledger. Beyond this limit, journal export requests throw <code>LimitExceededException</code>.</p>
  ## 
  let valid = call_611373.validator(path, query, header, formData, body)
  let scheme = call_611373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611373.url(scheme.get, call_611373.host, call_611373.base,
                         call_611373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611373, url, valid)

proc call*(call_611374: Call_ExportJournalToS3_611361; name: string; body: JsonNode): Recallable =
  ## exportJournalToS3
  ## <p>Exports journal contents within a date and time range from a ledger into a specified Amazon Simple Storage Service (Amazon S3) bucket. The data is written as files in Amazon Ion format.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>You can initiate up to two concurrent journal export requests for each ledger. Beyond this limit, journal export requests throw <code>LimitExceededException</code>.</p>
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_611375 = newJObject()
  var body_611376 = newJObject()
  add(path_611375, "name", newJString(name))
  if body != nil:
    body_611376 = body
  result = call_611374.call(path_611375, nil, nil, nil, body_611376)

var exportJournalToS3* = Call_ExportJournalToS3_611361(name: "exportJournalToS3",
    meth: HttpMethod.HttpPost, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}/journal-s3-exports",
    validator: validate_ExportJournalToS3_611362, base: "/",
    url: url_ExportJournalToS3_611363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJournalS3ExportsForLedger_611342 = ref object of OpenApiRestCall_610658
proc url_ListJournalS3ExportsForLedger_611344(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/journal-s3-exports")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListJournalS3ExportsForLedger_611343(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns an array of journal export job descriptions for a specified ledger.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3ExportsForLedger</code> multiple times.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the ledger.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_611345 = path.getOrDefault("name")
  valid_611345 = validateParameter(valid_611345, JString, required = true,
                                 default = nil)
  if valid_611345 != nil:
    section.add "name", valid_611345
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   next_token: JString
  ##             : A pagination token, indicating that you want to retrieve the next page of results. If you received a value for <code>NextToken</code> in the response from a previous <code>ListJournalS3ExportsForLedger</code> call, then you should use that value as input here.
  ##   max_results: JInt
  ##              : The maximum number of results to return in a single <code>ListJournalS3ExportsForLedger</code> request. (The actual number of results returned might be fewer.)
  section = newJObject()
  var valid_611346 = query.getOrDefault("MaxResults")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "MaxResults", valid_611346
  var valid_611347 = query.getOrDefault("NextToken")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "NextToken", valid_611347
  var valid_611348 = query.getOrDefault("next_token")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "next_token", valid_611348
  var valid_611349 = query.getOrDefault("max_results")
  valid_611349 = validateParameter(valid_611349, JInt, required = false, default = nil)
  if valid_611349 != nil:
    section.add "max_results", valid_611349
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
  var valid_611350 = header.getOrDefault("X-Amz-Signature")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-Signature", valid_611350
  var valid_611351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-Content-Sha256", valid_611351
  var valid_611352 = header.getOrDefault("X-Amz-Date")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Date", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-Credential")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Credential", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-Security-Token")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Security-Token", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Algorithm")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Algorithm", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-SignedHeaders", valid_611356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611357: Call_ListJournalS3ExportsForLedger_611342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an array of journal export job descriptions for a specified ledger.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3ExportsForLedger</code> multiple times.</p>
  ## 
  let valid = call_611357.validator(path, query, header, formData, body)
  let scheme = call_611357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611357.url(scheme.get, call_611357.host, call_611357.base,
                         call_611357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611357, url, valid)

proc call*(call_611358: Call_ListJournalS3ExportsForLedger_611342; name: string;
          MaxResults: string = ""; NextToken: string = ""; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listJournalS3ExportsForLedger
  ## <p>Returns an array of journal export job descriptions for a specified ledger.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3ExportsForLedger</code> multiple times.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   nextToken: string
  ##            : A pagination token, indicating that you want to retrieve the next page of results. If you received a value for <code>NextToken</code> in the response from a previous <code>ListJournalS3ExportsForLedger</code> call, then you should use that value as input here.
  ##   maxResults: int
  ##             : The maximum number of results to return in a single <code>ListJournalS3ExportsForLedger</code> request. (The actual number of results returned might be fewer.)
  var path_611359 = newJObject()
  var query_611360 = newJObject()
  add(query_611360, "MaxResults", newJString(MaxResults))
  add(query_611360, "NextToken", newJString(NextToken))
  add(path_611359, "name", newJString(name))
  add(query_611360, "next_token", newJString(nextToken))
  add(query_611360, "max_results", newJInt(maxResults))
  result = call_611358.call(path_611359, query_611360, nil, nil, nil)

var listJournalS3ExportsForLedger* = Call_ListJournalS3ExportsForLedger_611342(
    name: "listJournalS3ExportsForLedger", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com", route: "/ledgers/{name}/journal-s3-exports",
    validator: validate_ListJournalS3ExportsForLedger_611343, base: "/",
    url: url_ListJournalS3ExportsForLedger_611344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlock_611377 = ref object of OpenApiRestCall_610658
proc url_GetBlock_611379(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/block")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBlock_611378(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a journal block object at a specified address in a ledger. Also returns a proof of the specified block for verification if <code>DigestTipAddress</code> is provided.</p> <p>If the specified ledger doesn't exist or is in <code>DELETING</code> status, then throws <code>ResourceNotFoundException</code>.</p> <p>If the specified ledger is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>If no block exists with the specified address, then throws <code>InvalidParameterException</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the ledger.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_611380 = path.getOrDefault("name")
  valid_611380 = validateParameter(valid_611380, JString, required = true,
                                 default = nil)
  if valid_611380 != nil:
    section.add "name", valid_611380
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
  var valid_611381 = header.getOrDefault("X-Amz-Signature")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "X-Amz-Signature", valid_611381
  var valid_611382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-Content-Sha256", valid_611382
  var valid_611383 = header.getOrDefault("X-Amz-Date")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Date", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-Credential")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-Credential", valid_611384
  var valid_611385 = header.getOrDefault("X-Amz-Security-Token")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-Security-Token", valid_611385
  var valid_611386 = header.getOrDefault("X-Amz-Algorithm")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-Algorithm", valid_611386
  var valid_611387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-SignedHeaders", valid_611387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611389: Call_GetBlock_611377; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a journal block object at a specified address in a ledger. Also returns a proof of the specified block for verification if <code>DigestTipAddress</code> is provided.</p> <p>If the specified ledger doesn't exist or is in <code>DELETING</code> status, then throws <code>ResourceNotFoundException</code>.</p> <p>If the specified ledger is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>If no block exists with the specified address, then throws <code>InvalidParameterException</code>.</p>
  ## 
  let valid = call_611389.validator(path, query, header, formData, body)
  let scheme = call_611389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611389.url(scheme.get, call_611389.host, call_611389.base,
                         call_611389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611389, url, valid)

proc call*(call_611390: Call_GetBlock_611377; name: string; body: JsonNode): Recallable =
  ## getBlock
  ## <p>Returns a journal block object at a specified address in a ledger. Also returns a proof of the specified block for verification if <code>DigestTipAddress</code> is provided.</p> <p>If the specified ledger doesn't exist or is in <code>DELETING</code> status, then throws <code>ResourceNotFoundException</code>.</p> <p>If the specified ledger is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>If no block exists with the specified address, then throws <code>InvalidParameterException</code>.</p>
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_611391 = newJObject()
  var body_611392 = newJObject()
  add(path_611391, "name", newJString(name))
  if body != nil:
    body_611392 = body
  result = call_611390.call(path_611391, nil, nil, nil, body_611392)

var getBlock* = Call_GetBlock_611377(name: "getBlock", meth: HttpMethod.HttpPost,
                                  host: "qldb.amazonaws.com",
                                  route: "/ledgers/{name}/block",
                                  validator: validate_GetBlock_611378, base: "/",
                                  url: url_GetBlock_611379,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDigest_611393 = ref object of OpenApiRestCall_610658
proc url_GetDigest_611395(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/digest")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDigest_611394(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the digest of a ledger at the latest committed block in the journal. The response includes a 256-bit hash value and a block address.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the ledger.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_611396 = path.getOrDefault("name")
  valid_611396 = validateParameter(valid_611396, JString, required = true,
                                 default = nil)
  if valid_611396 != nil:
    section.add "name", valid_611396
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
  var valid_611397 = header.getOrDefault("X-Amz-Signature")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-Signature", valid_611397
  var valid_611398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-Content-Sha256", valid_611398
  var valid_611399 = header.getOrDefault("X-Amz-Date")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "X-Amz-Date", valid_611399
  var valid_611400 = header.getOrDefault("X-Amz-Credential")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-Credential", valid_611400
  var valid_611401 = header.getOrDefault("X-Amz-Security-Token")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "X-Amz-Security-Token", valid_611401
  var valid_611402 = header.getOrDefault("X-Amz-Algorithm")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "X-Amz-Algorithm", valid_611402
  var valid_611403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "X-Amz-SignedHeaders", valid_611403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611404: Call_GetDigest_611393; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the digest of a ledger at the latest committed block in the journal. The response includes a 256-bit hash value and a block address.
  ## 
  let valid = call_611404.validator(path, query, header, formData, body)
  let scheme = call_611404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611404.url(scheme.get, call_611404.host, call_611404.base,
                         call_611404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611404, url, valid)

proc call*(call_611405: Call_GetDigest_611393; name: string): Recallable =
  ## getDigest
  ## Returns the digest of a ledger at the latest committed block in the journal. The response includes a 256-bit hash value and a block address.
  ##   name: string (required)
  ##       : The name of the ledger.
  var path_611406 = newJObject()
  add(path_611406, "name", newJString(name))
  result = call_611405.call(path_611406, nil, nil, nil, nil)

var getDigest* = Call_GetDigest_611393(name: "getDigest", meth: HttpMethod.HttpPost,
                                    host: "qldb.amazonaws.com",
                                    route: "/ledgers/{name}/digest",
                                    validator: validate_GetDigest_611394,
                                    base: "/", url: url_GetDigest_611395,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevision_611407 = ref object of OpenApiRestCall_610658
proc url_GetRevision_611409(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/revision")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRevision_611408(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a revision data object for a specified document ID and block address. Also returns a proof of the specified revision for verification if <code>DigestTipAddress</code> is provided.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the ledger.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_611410 = path.getOrDefault("name")
  valid_611410 = validateParameter(valid_611410, JString, required = true,
                                 default = nil)
  if valid_611410 != nil:
    section.add "name", valid_611410
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
  var valid_611411 = header.getOrDefault("X-Amz-Signature")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Signature", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Content-Sha256", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-Date")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Date", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-Credential")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-Credential", valid_611414
  var valid_611415 = header.getOrDefault("X-Amz-Security-Token")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Security-Token", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-Algorithm")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-Algorithm", valid_611416
  var valid_611417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "X-Amz-SignedHeaders", valid_611417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611419: Call_GetRevision_611407; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a revision data object for a specified document ID and block address. Also returns a proof of the specified revision for verification if <code>DigestTipAddress</code> is provided.
  ## 
  let valid = call_611419.validator(path, query, header, formData, body)
  let scheme = call_611419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611419.url(scheme.get, call_611419.host, call_611419.base,
                         call_611419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611419, url, valid)

proc call*(call_611420: Call_GetRevision_611407; name: string; body: JsonNode): Recallable =
  ## getRevision
  ## Returns a revision data object for a specified document ID and block address. Also returns a proof of the specified revision for verification if <code>DigestTipAddress</code> is provided.
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_611421 = newJObject()
  var body_611422 = newJObject()
  add(path_611421, "name", newJString(name))
  if body != nil:
    body_611422 = body
  result = call_611420.call(path_611421, nil, nil, nil, body_611422)

var getRevision* = Call_GetRevision_611407(name: "getRevision",
                                        meth: HttpMethod.HttpPost,
                                        host: "qldb.amazonaws.com",
                                        route: "/ledgers/{name}/revision",
                                        validator: validate_GetRevision_611408,
                                        base: "/", url: url_GetRevision_611409,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJournalS3Exports_611423 = ref object of OpenApiRestCall_610658
proc url_ListJournalS3Exports_611425(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJournalS3Exports_611424(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns an array of journal export job descriptions for all ledgers that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3Exports</code> multiple times.</p>
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
  ##   next_token: JString
  ##             : A pagination token, indicating that you want to retrieve the next page of results. If you received a value for <code>NextToken</code> in the response from a previous <code>ListJournalS3Exports</code> call, then you should use that value as input here.
  ##   max_results: JInt
  ##              : The maximum number of results to return in a single <code>ListJournalS3Exports</code> request. (The actual number of results returned might be fewer.)
  section = newJObject()
  var valid_611426 = query.getOrDefault("MaxResults")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "MaxResults", valid_611426
  var valid_611427 = query.getOrDefault("NextToken")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "NextToken", valid_611427
  var valid_611428 = query.getOrDefault("next_token")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "next_token", valid_611428
  var valid_611429 = query.getOrDefault("max_results")
  valid_611429 = validateParameter(valid_611429, JInt, required = false, default = nil)
  if valid_611429 != nil:
    section.add "max_results", valid_611429
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
  var valid_611430 = header.getOrDefault("X-Amz-Signature")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-Signature", valid_611430
  var valid_611431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Content-Sha256", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-Date")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-Date", valid_611432
  var valid_611433 = header.getOrDefault("X-Amz-Credential")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-Credential", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Security-Token")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Security-Token", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Algorithm")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Algorithm", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-SignedHeaders", valid_611436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611437: Call_ListJournalS3Exports_611423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an array of journal export job descriptions for all ledgers that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3Exports</code> multiple times.</p>
  ## 
  let valid = call_611437.validator(path, query, header, formData, body)
  let scheme = call_611437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611437.url(scheme.get, call_611437.host, call_611437.base,
                         call_611437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611437, url, valid)

proc call*(call_611438: Call_ListJournalS3Exports_611423; MaxResults: string = "";
          NextToken: string = ""; nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listJournalS3Exports
  ## <p>Returns an array of journal export job descriptions for all ledgers that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3Exports</code> multiple times.</p>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##            : A pagination token, indicating that you want to retrieve the next page of results. If you received a value for <code>NextToken</code> in the response from a previous <code>ListJournalS3Exports</code> call, then you should use that value as input here.
  ##   maxResults: int
  ##             : The maximum number of results to return in a single <code>ListJournalS3Exports</code> request. (The actual number of results returned might be fewer.)
  var query_611439 = newJObject()
  add(query_611439, "MaxResults", newJString(MaxResults))
  add(query_611439, "NextToken", newJString(NextToken))
  add(query_611439, "next_token", newJString(nextToken))
  add(query_611439, "max_results", newJInt(maxResults))
  result = call_611438.call(nil, query_611439, nil, nil, nil)

var listJournalS3Exports* = Call_ListJournalS3Exports_611423(
    name: "listJournalS3Exports", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com", route: "/journal-s3-exports",
    validator: validate_ListJournalS3Exports_611424, base: "/",
    url: url_ListJournalS3Exports_611425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_611454 = ref object of OpenApiRestCall_610658
proc url_TagResource_611456(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_611455(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds one or more tags to a specified Amazon QLDB resource.</p> <p>A resource can have up to 50 tags. If you try to create more than 50 tags for a resource, your request fails and returns an error.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) to which you want to add the tags. For example:</p> <p> <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> </p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_611457 = path.getOrDefault("resourceArn")
  valid_611457 = validateParameter(valid_611457, JString, required = true,
                                 default = nil)
  if valid_611457 != nil:
    section.add "resourceArn", valid_611457
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
  var valid_611458 = header.getOrDefault("X-Amz-Signature")
  valid_611458 = validateParameter(valid_611458, JString, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "X-Amz-Signature", valid_611458
  var valid_611459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "X-Amz-Content-Sha256", valid_611459
  var valid_611460 = header.getOrDefault("X-Amz-Date")
  valid_611460 = validateParameter(valid_611460, JString, required = false,
                                 default = nil)
  if valid_611460 != nil:
    section.add "X-Amz-Date", valid_611460
  var valid_611461 = header.getOrDefault("X-Amz-Credential")
  valid_611461 = validateParameter(valid_611461, JString, required = false,
                                 default = nil)
  if valid_611461 != nil:
    section.add "X-Amz-Credential", valid_611461
  var valid_611462 = header.getOrDefault("X-Amz-Security-Token")
  valid_611462 = validateParameter(valid_611462, JString, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "X-Amz-Security-Token", valid_611462
  var valid_611463 = header.getOrDefault("X-Amz-Algorithm")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "X-Amz-Algorithm", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-SignedHeaders", valid_611464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611466: Call_TagResource_611454; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to a specified Amazon QLDB resource.</p> <p>A resource can have up to 50 tags. If you try to create more than 50 tags for a resource, your request fails and returns an error.</p>
  ## 
  let valid = call_611466.validator(path, query, header, formData, body)
  let scheme = call_611466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611466.url(scheme.get, call_611466.host, call_611466.base,
                         call_611466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611466, url, valid)

proc call*(call_611467: Call_TagResource_611454; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds one or more tags to a specified Amazon QLDB resource.</p> <p>A resource can have up to 50 tags. If you try to create more than 50 tags for a resource, your request fails and returns an error.</p>
  ##   resourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) to which you want to add the tags. For example:</p> <p> <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> </p>
  ##   body: JObject (required)
  var path_611468 = newJObject()
  var body_611469 = newJObject()
  add(path_611468, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_611469 = body
  result = call_611467.call(path_611468, nil, nil, nil, body_611469)

var tagResource* = Call_TagResource_611454(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "qldb.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_611455,
                                        base: "/", url: url_TagResource_611456,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_611440 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_611442(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_611441(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns all tags for a specified Amazon QLDB resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) for which you want to list the tags. For example:</p> <p> <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> </p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_611443 = path.getOrDefault("resourceArn")
  valid_611443 = validateParameter(valid_611443, JString, required = true,
                                 default = nil)
  if valid_611443 != nil:
    section.add "resourceArn", valid_611443
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
  var valid_611444 = header.getOrDefault("X-Amz-Signature")
  valid_611444 = validateParameter(valid_611444, JString, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "X-Amz-Signature", valid_611444
  var valid_611445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "X-Amz-Content-Sha256", valid_611445
  var valid_611446 = header.getOrDefault("X-Amz-Date")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-Date", valid_611446
  var valid_611447 = header.getOrDefault("X-Amz-Credential")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-Credential", valid_611447
  var valid_611448 = header.getOrDefault("X-Amz-Security-Token")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-Security-Token", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Algorithm")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Algorithm", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-SignedHeaders", valid_611450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611451: Call_ListTagsForResource_611440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tags for a specified Amazon QLDB resource.
  ## 
  let valid = call_611451.validator(path, query, header, formData, body)
  let scheme = call_611451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611451.url(scheme.get, call_611451.host, call_611451.base,
                         call_611451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611451, url, valid)

proc call*(call_611452: Call_ListTagsForResource_611440; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns all tags for a specified Amazon QLDB resource.
  ##   resourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) for which you want to list the tags. For example:</p> <p> <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> </p>
  var path_611453 = newJObject()
  add(path_611453, "resourceArn", newJString(resourceArn))
  result = call_611452.call(path_611453, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_611440(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_611441, base: "/",
    url: url_ListTagsForResource_611442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_611470 = ref object of OpenApiRestCall_610658
proc url_UntagResource_611472(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_611471(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes one or more tags from a specified Amazon QLDB resource. You can specify up to 50 tag keys to remove.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) from which you want to remove the tags. For example:</p> <p> <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> </p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_611473 = path.getOrDefault("resourceArn")
  valid_611473 = validateParameter(valid_611473, JString, required = true,
                                 default = nil)
  if valid_611473 != nil:
    section.add "resourceArn", valid_611473
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The list of tag keys that you want to remove.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_611474 = query.getOrDefault("tagKeys")
  valid_611474 = validateParameter(valid_611474, JArray, required = true, default = nil)
  if valid_611474 != nil:
    section.add "tagKeys", valid_611474
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
  var valid_611475 = header.getOrDefault("X-Amz-Signature")
  valid_611475 = validateParameter(valid_611475, JString, required = false,
                                 default = nil)
  if valid_611475 != nil:
    section.add "X-Amz-Signature", valid_611475
  var valid_611476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "X-Amz-Content-Sha256", valid_611476
  var valid_611477 = header.getOrDefault("X-Amz-Date")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "X-Amz-Date", valid_611477
  var valid_611478 = header.getOrDefault("X-Amz-Credential")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "X-Amz-Credential", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Security-Token")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Security-Token", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-Algorithm")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Algorithm", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-SignedHeaders", valid_611481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611482: Call_UntagResource_611470; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a specified Amazon QLDB resource. You can specify up to 50 tag keys to remove.
  ## 
  let valid = call_611482.validator(path, query, header, formData, body)
  let scheme = call_611482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611482.url(scheme.get, call_611482.host, call_611482.base,
                         call_611482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611482, url, valid)

proc call*(call_611483: Call_UntagResource_611470; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from a specified Amazon QLDB resource. You can specify up to 50 tag keys to remove.
  ##   resourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) from which you want to remove the tags. For example:</p> <p> <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> </p>
  ##   tagKeys: JArray (required)
  ##          : The list of tag keys that you want to remove.
  var path_611484 = newJObject()
  var query_611485 = newJObject()
  add(path_611484, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_611485.add "tagKeys", tagKeys
  result = call_611483.call(path_611484, query_611485, nil, nil, nil)

var untagResource* = Call_UntagResource_611470(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "qldb.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_611471,
    base: "/", url: url_UntagResource_611472, schemes: {Scheme.Https, Scheme.Http})
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
