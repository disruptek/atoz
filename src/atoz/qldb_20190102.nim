
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateLedger_594033 = ref object of OpenApiRestCall_593437
proc url_CreateLedger_594035(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLedger_594034(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594036 = header.getOrDefault("X-Amz-Date")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-Date", valid_594036
  var valid_594037 = header.getOrDefault("X-Amz-Security-Token")
  valid_594037 = validateParameter(valid_594037, JString, required = false,
                                 default = nil)
  if valid_594037 != nil:
    section.add "X-Amz-Security-Token", valid_594037
  var valid_594038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594038 = validateParameter(valid_594038, JString, required = false,
                                 default = nil)
  if valid_594038 != nil:
    section.add "X-Amz-Content-Sha256", valid_594038
  var valid_594039 = header.getOrDefault("X-Amz-Algorithm")
  valid_594039 = validateParameter(valid_594039, JString, required = false,
                                 default = nil)
  if valid_594039 != nil:
    section.add "X-Amz-Algorithm", valid_594039
  var valid_594040 = header.getOrDefault("X-Amz-Signature")
  valid_594040 = validateParameter(valid_594040, JString, required = false,
                                 default = nil)
  if valid_594040 != nil:
    section.add "X-Amz-Signature", valid_594040
  var valid_594041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594041 = validateParameter(valid_594041, JString, required = false,
                                 default = nil)
  if valid_594041 != nil:
    section.add "X-Amz-SignedHeaders", valid_594041
  var valid_594042 = header.getOrDefault("X-Amz-Credential")
  valid_594042 = validateParameter(valid_594042, JString, required = false,
                                 default = nil)
  if valid_594042 != nil:
    section.add "X-Amz-Credential", valid_594042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594044: Call_CreateLedger_594033; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new ledger in your AWS account.
  ## 
  let valid = call_594044.validator(path, query, header, formData, body)
  let scheme = call_594044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594044.url(scheme.get, call_594044.host, call_594044.base,
                         call_594044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594044, url, valid)

proc call*(call_594045: Call_CreateLedger_594033; body: JsonNode): Recallable =
  ## createLedger
  ## Creates a new ledger in your AWS account.
  ##   body: JObject (required)
  var body_594046 = newJObject()
  if body != nil:
    body_594046 = body
  result = call_594045.call(nil, nil, nil, nil, body_594046)

var createLedger* = Call_CreateLedger_594033(name: "createLedger",
    meth: HttpMethod.HttpPost, host: "qldb.amazonaws.com", route: "/ledgers",
    validator: validate_CreateLedger_594034, base: "/", url: url_CreateLedger_594035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLedgers_593774 = ref object of OpenApiRestCall_593437
proc url_ListLedgers_593776(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLedgers_593775(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns an array of ledger summaries that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of 100 items and is paginated so that you can retrieve all the items by calling <code>ListLedgers</code> multiple times.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   next_token: JString
  ##             : A pagination token, indicating that you want to retrieve the next page of results. If you received a value for <code>NextToken</code> in the response from a previous <code>ListLedgers</code> call, then you should use that value as input here.
  ##   max_results: JInt
  ##              : The maximum number of results to return in a single <code>ListLedgers</code> request. (The actual number of results returned might be fewer.)
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_593888 = query.getOrDefault("NextToken")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "NextToken", valid_593888
  var valid_593889 = query.getOrDefault("next_token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "next_token", valid_593889
  var valid_593890 = query.getOrDefault("max_results")
  valid_593890 = validateParameter(valid_593890, JInt, required = false, default = nil)
  if valid_593890 != nil:
    section.add "max_results", valid_593890
  var valid_593891 = query.getOrDefault("MaxResults")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "MaxResults", valid_593891
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
  var valid_593892 = header.getOrDefault("X-Amz-Date")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "X-Amz-Date", valid_593892
  var valid_593893 = header.getOrDefault("X-Amz-Security-Token")
  valid_593893 = validateParameter(valid_593893, JString, required = false,
                                 default = nil)
  if valid_593893 != nil:
    section.add "X-Amz-Security-Token", valid_593893
  var valid_593894 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593894 = validateParameter(valid_593894, JString, required = false,
                                 default = nil)
  if valid_593894 != nil:
    section.add "X-Amz-Content-Sha256", valid_593894
  var valid_593895 = header.getOrDefault("X-Amz-Algorithm")
  valid_593895 = validateParameter(valid_593895, JString, required = false,
                                 default = nil)
  if valid_593895 != nil:
    section.add "X-Amz-Algorithm", valid_593895
  var valid_593896 = header.getOrDefault("X-Amz-Signature")
  valid_593896 = validateParameter(valid_593896, JString, required = false,
                                 default = nil)
  if valid_593896 != nil:
    section.add "X-Amz-Signature", valid_593896
  var valid_593897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593897 = validateParameter(valid_593897, JString, required = false,
                                 default = nil)
  if valid_593897 != nil:
    section.add "X-Amz-SignedHeaders", valid_593897
  var valid_593898 = header.getOrDefault("X-Amz-Credential")
  valid_593898 = validateParameter(valid_593898, JString, required = false,
                                 default = nil)
  if valid_593898 != nil:
    section.add "X-Amz-Credential", valid_593898
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593921: Call_ListLedgers_593774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an array of ledger summaries that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of 100 items and is paginated so that you can retrieve all the items by calling <code>ListLedgers</code> multiple times.</p>
  ## 
  let valid = call_593921.validator(path, query, header, formData, body)
  let scheme = call_593921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593921.url(scheme.get, call_593921.host, call_593921.base,
                         call_593921.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593921, url, valid)

proc call*(call_593992: Call_ListLedgers_593774; NextToken: string = "";
          nextToken: string = ""; maxResults: int = 0; MaxResults: string = ""): Recallable =
  ## listLedgers
  ## <p>Returns an array of ledger summaries that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of 100 items and is paginated so that you can retrieve all the items by calling <code>ListLedgers</code> multiple times.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##            : A pagination token, indicating that you want to retrieve the next page of results. If you received a value for <code>NextToken</code> in the response from a previous <code>ListLedgers</code> call, then you should use that value as input here.
  ##   maxResults: int
  ##             : The maximum number of results to return in a single <code>ListLedgers</code> request. (The actual number of results returned might be fewer.)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_593993 = newJObject()
  add(query_593993, "NextToken", newJString(NextToken))
  add(query_593993, "next_token", newJString(nextToken))
  add(query_593993, "max_results", newJInt(maxResults))
  add(query_593993, "MaxResults", newJString(MaxResults))
  result = call_593992.call(nil, query_593993, nil, nil, nil)

var listLedgers* = Call_ListLedgers_593774(name: "listLedgers",
                                        meth: HttpMethod.HttpGet,
                                        host: "qldb.amazonaws.com",
                                        route: "/ledgers",
                                        validator: validate_ListLedgers_593775,
                                        base: "/", url: url_ListLedgers_593776,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLedger_594047 = ref object of OpenApiRestCall_593437
proc url_DescribeLedger_594049(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeLedger_594048(path: JsonNode; query: JsonNode;
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
  var valid_594064 = path.getOrDefault("name")
  valid_594064 = validateParameter(valid_594064, JString, required = true,
                                 default = nil)
  if valid_594064 != nil:
    section.add "name", valid_594064
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
  var valid_594065 = header.getOrDefault("X-Amz-Date")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Date", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Security-Token")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Security-Token", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Content-Sha256", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Algorithm")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Algorithm", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-Signature")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Signature", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-SignedHeaders", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Credential")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Credential", valid_594071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594072: Call_DescribeLedger_594047; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a ledger, including its state and when it was created.
  ## 
  let valid = call_594072.validator(path, query, header, formData, body)
  let scheme = call_594072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594072.url(scheme.get, call_594072.host, call_594072.base,
                         call_594072.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594072, url, valid)

proc call*(call_594073: Call_DescribeLedger_594047; name: string): Recallable =
  ## describeLedger
  ## Returns information about a ledger, including its state and when it was created.
  ##   name: string (required)
  ##       : The name of the ledger that you want to describe.
  var path_594074 = newJObject()
  add(path_594074, "name", newJString(name))
  result = call_594073.call(path_594074, nil, nil, nil, nil)

var describeLedger* = Call_DescribeLedger_594047(name: "describeLedger",
    meth: HttpMethod.HttpGet, host: "qldb.amazonaws.com", route: "/ledgers/{name}",
    validator: validate_DescribeLedger_594048, base: "/", url: url_DescribeLedger_594049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLedger_594089 = ref object of OpenApiRestCall_593437
proc url_UpdateLedger_594091(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateLedger_594090(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594092 = path.getOrDefault("name")
  valid_594092 = validateParameter(valid_594092, JString, required = true,
                                 default = nil)
  if valid_594092 != nil:
    section.add "name", valid_594092
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
  var valid_594093 = header.getOrDefault("X-Amz-Date")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Date", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Security-Token")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Security-Token", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Content-Sha256", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Algorithm")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Algorithm", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-Signature")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Signature", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-SignedHeaders", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-Credential")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Credential", valid_594099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594101: Call_UpdateLedger_594089; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates properties on a ledger.
  ## 
  let valid = call_594101.validator(path, query, header, formData, body)
  let scheme = call_594101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594101.url(scheme.get, call_594101.host, call_594101.base,
                         call_594101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594101, url, valid)

proc call*(call_594102: Call_UpdateLedger_594089; name: string; body: JsonNode): Recallable =
  ## updateLedger
  ## Updates properties on a ledger.
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_594103 = newJObject()
  var body_594104 = newJObject()
  add(path_594103, "name", newJString(name))
  if body != nil:
    body_594104 = body
  result = call_594102.call(path_594103, nil, nil, nil, body_594104)

var updateLedger* = Call_UpdateLedger_594089(name: "updateLedger",
    meth: HttpMethod.HttpPatch, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}", validator: validate_UpdateLedger_594090, base: "/",
    url: url_UpdateLedger_594091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLedger_594075 = ref object of OpenApiRestCall_593437
proc url_DeleteLedger_594077(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteLedger_594076(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594078 = path.getOrDefault("name")
  valid_594078 = validateParameter(valid_594078, JString, required = true,
                                 default = nil)
  if valid_594078 != nil:
    section.add "name", valid_594078
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
  var valid_594079 = header.getOrDefault("X-Amz-Date")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Date", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Security-Token")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Security-Token", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Content-Sha256", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Algorithm")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Algorithm", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Signature")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Signature", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-SignedHeaders", valid_594084
  var valid_594085 = header.getOrDefault("X-Amz-Credential")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "X-Amz-Credential", valid_594085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594086: Call_DeleteLedger_594075; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a ledger and all of its contents. This action is irreversible.</p> <p>If deletion protection is enabled, you must first disable it before you can delete the ledger using the QLDB API or the AWS Command Line Interface (AWS CLI). You can disable it by calling the <code>UpdateLedger</code> operation to set the flag to <code>false</code>. The QLDB console disables deletion protection for you when you use it to delete a ledger.</p>
  ## 
  let valid = call_594086.validator(path, query, header, formData, body)
  let scheme = call_594086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594086.url(scheme.get, call_594086.host, call_594086.base,
                         call_594086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594086, url, valid)

proc call*(call_594087: Call_DeleteLedger_594075; name: string): Recallable =
  ## deleteLedger
  ## <p>Deletes a ledger and all of its contents. This action is irreversible.</p> <p>If deletion protection is enabled, you must first disable it before you can delete the ledger using the QLDB API or the AWS Command Line Interface (AWS CLI). You can disable it by calling the <code>UpdateLedger</code> operation to set the flag to <code>false</code>. The QLDB console disables deletion protection for you when you use it to delete a ledger.</p>
  ##   name: string (required)
  ##       : The name of the ledger that you want to delete.
  var path_594088 = newJObject()
  add(path_594088, "name", newJString(name))
  result = call_594087.call(path_594088, nil, nil, nil, nil)

var deleteLedger* = Call_DeleteLedger_594075(name: "deleteLedger",
    meth: HttpMethod.HttpDelete, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}", validator: validate_DeleteLedger_594076, base: "/",
    url: url_DeleteLedger_594077, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJournalS3Export_594105 = ref object of OpenApiRestCall_593437
proc url_DescribeJournalS3Export_594107(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeJournalS3Export_594106(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about a journal export job, including the ledger name, export ID, when it was created, current status, and its start and end time export parameters.</p> <p>If the export job with the given <code>ExportId</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the ledger.
  ##   exportId: JString (required)
  ##           : The unique ID of the journal export job that you want to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_594108 = path.getOrDefault("name")
  valid_594108 = validateParameter(valid_594108, JString, required = true,
                                 default = nil)
  if valid_594108 != nil:
    section.add "name", valid_594108
  var valid_594109 = path.getOrDefault("exportId")
  valid_594109 = validateParameter(valid_594109, JString, required = true,
                                 default = nil)
  if valid_594109 != nil:
    section.add "exportId", valid_594109
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
  var valid_594110 = header.getOrDefault("X-Amz-Date")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Date", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Security-Token")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Security-Token", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Content-Sha256", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Algorithm")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Algorithm", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Signature")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Signature", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-SignedHeaders", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-Credential")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-Credential", valid_594116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594117: Call_DescribeJournalS3Export_594105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a journal export job, including the ledger name, export ID, when it was created, current status, and its start and end time export parameters.</p> <p>If the export job with the given <code>ExportId</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p>
  ## 
  let valid = call_594117.validator(path, query, header, formData, body)
  let scheme = call_594117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594117.url(scheme.get, call_594117.host, call_594117.base,
                         call_594117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594117, url, valid)

proc call*(call_594118: Call_DescribeJournalS3Export_594105; name: string;
          exportId: string): Recallable =
  ## describeJournalS3Export
  ## <p>Returns information about a journal export job, including the ledger name, export ID, when it was created, current status, and its start and end time export parameters.</p> <p>If the export job with the given <code>ExportId</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p>
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   exportId: string (required)
  ##           : The unique ID of the journal export job that you want to describe.
  var path_594119 = newJObject()
  add(path_594119, "name", newJString(name))
  add(path_594119, "exportId", newJString(exportId))
  result = call_594118.call(path_594119, nil, nil, nil, nil)

var describeJournalS3Export* = Call_DescribeJournalS3Export_594105(
    name: "describeJournalS3Export", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com",
    route: "/ledgers/{name}/journal-s3-exports/{exportId}",
    validator: validate_DescribeJournalS3Export_594106, base: "/",
    url: url_DescribeJournalS3Export_594107, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportJournalToS3_594139 = ref object of OpenApiRestCall_593437
proc url_ExportJournalToS3_594141(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ExportJournalToS3_594140(path: JsonNode; query: JsonNode;
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
  var valid_594142 = path.getOrDefault("name")
  valid_594142 = validateParameter(valid_594142, JString, required = true,
                                 default = nil)
  if valid_594142 != nil:
    section.add "name", valid_594142
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
  var valid_594143 = header.getOrDefault("X-Amz-Date")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Date", valid_594143
  var valid_594144 = header.getOrDefault("X-Amz-Security-Token")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-Security-Token", valid_594144
  var valid_594145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-Content-Sha256", valid_594145
  var valid_594146 = header.getOrDefault("X-Amz-Algorithm")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Algorithm", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Signature")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Signature", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-SignedHeaders", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Credential")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Credential", valid_594149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594151: Call_ExportJournalToS3_594139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Exports journal contents within a date and time range from a ledger into a specified Amazon Simple Storage Service (Amazon S3) bucket. The data is written as files in Amazon Ion format.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>You can initiate up to two concurrent journal export requests for each ledger. Beyond this limit, journal export requests throw <code>LimitExceededException</code>.</p>
  ## 
  let valid = call_594151.validator(path, query, header, formData, body)
  let scheme = call_594151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594151.url(scheme.get, call_594151.host, call_594151.base,
                         call_594151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594151, url, valid)

proc call*(call_594152: Call_ExportJournalToS3_594139; name: string; body: JsonNode): Recallable =
  ## exportJournalToS3
  ## <p>Exports journal contents within a date and time range from a ledger into a specified Amazon Simple Storage Service (Amazon S3) bucket. The data is written as files in Amazon Ion format.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>You can initiate up to two concurrent journal export requests for each ledger. Beyond this limit, journal export requests throw <code>LimitExceededException</code>.</p>
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_594153 = newJObject()
  var body_594154 = newJObject()
  add(path_594153, "name", newJString(name))
  if body != nil:
    body_594154 = body
  result = call_594152.call(path_594153, nil, nil, nil, body_594154)

var exportJournalToS3* = Call_ExportJournalToS3_594139(name: "exportJournalToS3",
    meth: HttpMethod.HttpPost, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}/journal-s3-exports",
    validator: validate_ExportJournalToS3_594140, base: "/",
    url: url_ExportJournalToS3_594141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJournalS3ExportsForLedger_594120 = ref object of OpenApiRestCall_593437
proc url_ListJournalS3ExportsForLedger_594122(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_ListJournalS3ExportsForLedger_594121(path: JsonNode; query: JsonNode;
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
  var valid_594123 = path.getOrDefault("name")
  valid_594123 = validateParameter(valid_594123, JString, required = true,
                                 default = nil)
  if valid_594123 != nil:
    section.add "name", valid_594123
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   next_token: JString
  ##             : A pagination token, indicating that you want to retrieve the next page of results. If you received a value for <code>NextToken</code> in the response from a previous <code>ListJournalS3ExportsForLedger</code> call, then you should use that value as input here.
  ##   max_results: JInt
  ##              : The maximum number of results to return in a single <code>ListJournalS3ExportsForLedger</code> request. (The actual number of results returned might be fewer.)
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594124 = query.getOrDefault("NextToken")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "NextToken", valid_594124
  var valid_594125 = query.getOrDefault("next_token")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "next_token", valid_594125
  var valid_594126 = query.getOrDefault("max_results")
  valid_594126 = validateParameter(valid_594126, JInt, required = false, default = nil)
  if valid_594126 != nil:
    section.add "max_results", valid_594126
  var valid_594127 = query.getOrDefault("MaxResults")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "MaxResults", valid_594127
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
  var valid_594128 = header.getOrDefault("X-Amz-Date")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Date", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Security-Token")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Security-Token", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Content-Sha256", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-Algorithm")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Algorithm", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Signature")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Signature", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-SignedHeaders", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-Credential")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-Credential", valid_594134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594135: Call_ListJournalS3ExportsForLedger_594120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an array of journal export job descriptions for a specified ledger.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3ExportsForLedger</code> multiple times.</p>
  ## 
  let valid = call_594135.validator(path, query, header, formData, body)
  let scheme = call_594135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594135.url(scheme.get, call_594135.host, call_594135.base,
                         call_594135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594135, url, valid)

proc call*(call_594136: Call_ListJournalS3ExportsForLedger_594120; name: string;
          NextToken: string = ""; nextToken: string = ""; maxResults: int = 0;
          MaxResults: string = ""): Recallable =
  ## listJournalS3ExportsForLedger
  ## <p>Returns an array of journal export job descriptions for a specified ledger.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3ExportsForLedger</code> multiple times.</p>
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##            : A pagination token, indicating that you want to retrieve the next page of results. If you received a value for <code>NextToken</code> in the response from a previous <code>ListJournalS3ExportsForLedger</code> call, then you should use that value as input here.
  ##   maxResults: int
  ##             : The maximum number of results to return in a single <code>ListJournalS3ExportsForLedger</code> request. (The actual number of results returned might be fewer.)
  ##   MaxResults: string
  ##             : Pagination limit
  var path_594137 = newJObject()
  var query_594138 = newJObject()
  add(path_594137, "name", newJString(name))
  add(query_594138, "NextToken", newJString(NextToken))
  add(query_594138, "next_token", newJString(nextToken))
  add(query_594138, "max_results", newJInt(maxResults))
  add(query_594138, "MaxResults", newJString(MaxResults))
  result = call_594136.call(path_594137, query_594138, nil, nil, nil)

var listJournalS3ExportsForLedger* = Call_ListJournalS3ExportsForLedger_594120(
    name: "listJournalS3ExportsForLedger", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com", route: "/ledgers/{name}/journal-s3-exports",
    validator: validate_ListJournalS3ExportsForLedger_594121, base: "/",
    url: url_ListJournalS3ExportsForLedger_594122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlock_594155 = ref object of OpenApiRestCall_593437
proc url_GetBlock_594157(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetBlock_594156(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594158 = path.getOrDefault("name")
  valid_594158 = validateParameter(valid_594158, JString, required = true,
                                 default = nil)
  if valid_594158 != nil:
    section.add "name", valid_594158
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
  var valid_594159 = header.getOrDefault("X-Amz-Date")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-Date", valid_594159
  var valid_594160 = header.getOrDefault("X-Amz-Security-Token")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "X-Amz-Security-Token", valid_594160
  var valid_594161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Content-Sha256", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-Algorithm")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-Algorithm", valid_594162
  var valid_594163 = header.getOrDefault("X-Amz-Signature")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Signature", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-SignedHeaders", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-Credential")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Credential", valid_594165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594167: Call_GetBlock_594155; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a journal block object at a specified address in a ledger. Also returns a proof of the specified block for verification if <code>DigestTipAddress</code> is provided.</p> <p>If the specified ledger doesn't exist or is in <code>DELETING</code> status, then throws <code>ResourceNotFoundException</code>.</p> <p>If the specified ledger is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>If no block exists with the specified address, then throws <code>InvalidParameterException</code>.</p>
  ## 
  let valid = call_594167.validator(path, query, header, formData, body)
  let scheme = call_594167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594167.url(scheme.get, call_594167.host, call_594167.base,
                         call_594167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594167, url, valid)

proc call*(call_594168: Call_GetBlock_594155; name: string; body: JsonNode): Recallable =
  ## getBlock
  ## <p>Returns a journal block object at a specified address in a ledger. Also returns a proof of the specified block for verification if <code>DigestTipAddress</code> is provided.</p> <p>If the specified ledger doesn't exist or is in <code>DELETING</code> status, then throws <code>ResourceNotFoundException</code>.</p> <p>If the specified ledger is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>If no block exists with the specified address, then throws <code>InvalidParameterException</code>.</p>
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_594169 = newJObject()
  var body_594170 = newJObject()
  add(path_594169, "name", newJString(name))
  if body != nil:
    body_594170 = body
  result = call_594168.call(path_594169, nil, nil, nil, body_594170)

var getBlock* = Call_GetBlock_594155(name: "getBlock", meth: HttpMethod.HttpPost,
                                  host: "qldb.amazonaws.com",
                                  route: "/ledgers/{name}/block",
                                  validator: validate_GetBlock_594156, base: "/",
                                  url: url_GetBlock_594157,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDigest_594171 = ref object of OpenApiRestCall_593437
proc url_GetDigest_594173(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_GetDigest_594172(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594174 = path.getOrDefault("name")
  valid_594174 = validateParameter(valid_594174, JString, required = true,
                                 default = nil)
  if valid_594174 != nil:
    section.add "name", valid_594174
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
  var valid_594175 = header.getOrDefault("X-Amz-Date")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "X-Amz-Date", valid_594175
  var valid_594176 = header.getOrDefault("X-Amz-Security-Token")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "X-Amz-Security-Token", valid_594176
  var valid_594177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "X-Amz-Content-Sha256", valid_594177
  var valid_594178 = header.getOrDefault("X-Amz-Algorithm")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "X-Amz-Algorithm", valid_594178
  var valid_594179 = header.getOrDefault("X-Amz-Signature")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "X-Amz-Signature", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-SignedHeaders", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-Credential")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Credential", valid_594181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594182: Call_GetDigest_594171; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the digest of a ledger at the latest committed block in the journal. The response includes a 256-bit hash value and a block address.
  ## 
  let valid = call_594182.validator(path, query, header, formData, body)
  let scheme = call_594182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594182.url(scheme.get, call_594182.host, call_594182.base,
                         call_594182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594182, url, valid)

proc call*(call_594183: Call_GetDigest_594171; name: string): Recallable =
  ## getDigest
  ## Returns the digest of a ledger at the latest committed block in the journal. The response includes a 256-bit hash value and a block address.
  ##   name: string (required)
  ##       : The name of the ledger.
  var path_594184 = newJObject()
  add(path_594184, "name", newJString(name))
  result = call_594183.call(path_594184, nil, nil, nil, nil)

var getDigest* = Call_GetDigest_594171(name: "getDigest", meth: HttpMethod.HttpPost,
                                    host: "qldb.amazonaws.com",
                                    route: "/ledgers/{name}/digest",
                                    validator: validate_GetDigest_594172,
                                    base: "/", url: url_GetDigest_594173,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevision_594185 = ref object of OpenApiRestCall_593437
proc url_GetRevision_594187(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_GetRevision_594186(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594188 = path.getOrDefault("name")
  valid_594188 = validateParameter(valid_594188, JString, required = true,
                                 default = nil)
  if valid_594188 != nil:
    section.add "name", valid_594188
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
  var valid_594189 = header.getOrDefault("X-Amz-Date")
  valid_594189 = validateParameter(valid_594189, JString, required = false,
                                 default = nil)
  if valid_594189 != nil:
    section.add "X-Amz-Date", valid_594189
  var valid_594190 = header.getOrDefault("X-Amz-Security-Token")
  valid_594190 = validateParameter(valid_594190, JString, required = false,
                                 default = nil)
  if valid_594190 != nil:
    section.add "X-Amz-Security-Token", valid_594190
  var valid_594191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "X-Amz-Content-Sha256", valid_594191
  var valid_594192 = header.getOrDefault("X-Amz-Algorithm")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "X-Amz-Algorithm", valid_594192
  var valid_594193 = header.getOrDefault("X-Amz-Signature")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-Signature", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-SignedHeaders", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-Credential")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Credential", valid_594195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594197: Call_GetRevision_594185; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a revision data object for a specified document ID and block address. Also returns a proof of the specified revision for verification if <code>DigestTipAddress</code> is provided.
  ## 
  let valid = call_594197.validator(path, query, header, formData, body)
  let scheme = call_594197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594197.url(scheme.get, call_594197.host, call_594197.base,
                         call_594197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594197, url, valid)

proc call*(call_594198: Call_GetRevision_594185; name: string; body: JsonNode): Recallable =
  ## getRevision
  ## Returns a revision data object for a specified document ID and block address. Also returns a proof of the specified revision for verification if <code>DigestTipAddress</code> is provided.
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_594199 = newJObject()
  var body_594200 = newJObject()
  add(path_594199, "name", newJString(name))
  if body != nil:
    body_594200 = body
  result = call_594198.call(path_594199, nil, nil, nil, body_594200)

var getRevision* = Call_GetRevision_594185(name: "getRevision",
                                        meth: HttpMethod.HttpPost,
                                        host: "qldb.amazonaws.com",
                                        route: "/ledgers/{name}/revision",
                                        validator: validate_GetRevision_594186,
                                        base: "/", url: url_GetRevision_594187,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJournalS3Exports_594201 = ref object of OpenApiRestCall_593437
proc url_ListJournalS3Exports_594203(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListJournalS3Exports_594202(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns an array of journal export job descriptions for all ledgers that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3Exports</code> multiple times.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   next_token: JString
  ##             : A pagination token, indicating that you want to retrieve the next page of results. If you received a value for <code>NextToken</code> in the response from a previous <code>ListJournalS3Exports</code> call, then you should use that value as input here.
  ##   max_results: JInt
  ##              : The maximum number of results to return in a single <code>ListJournalS3Exports</code> request. (The actual number of results returned might be fewer.)
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594204 = query.getOrDefault("NextToken")
  valid_594204 = validateParameter(valid_594204, JString, required = false,
                                 default = nil)
  if valid_594204 != nil:
    section.add "NextToken", valid_594204
  var valid_594205 = query.getOrDefault("next_token")
  valid_594205 = validateParameter(valid_594205, JString, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "next_token", valid_594205
  var valid_594206 = query.getOrDefault("max_results")
  valid_594206 = validateParameter(valid_594206, JInt, required = false, default = nil)
  if valid_594206 != nil:
    section.add "max_results", valid_594206
  var valid_594207 = query.getOrDefault("MaxResults")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "MaxResults", valid_594207
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
  var valid_594208 = header.getOrDefault("X-Amz-Date")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "X-Amz-Date", valid_594208
  var valid_594209 = header.getOrDefault("X-Amz-Security-Token")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Security-Token", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Content-Sha256", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Algorithm")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Algorithm", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Signature")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Signature", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-SignedHeaders", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Credential")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Credential", valid_594214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594215: Call_ListJournalS3Exports_594201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an array of journal export job descriptions for all ledgers that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3Exports</code> multiple times.</p>
  ## 
  let valid = call_594215.validator(path, query, header, formData, body)
  let scheme = call_594215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594215.url(scheme.get, call_594215.host, call_594215.base,
                         call_594215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594215, url, valid)

proc call*(call_594216: Call_ListJournalS3Exports_594201; NextToken: string = "";
          nextToken: string = ""; maxResults: int = 0; MaxResults: string = ""): Recallable =
  ## listJournalS3Exports
  ## <p>Returns an array of journal export job descriptions for all ledgers that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3Exports</code> multiple times.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   nextToken: string
  ##            : A pagination token, indicating that you want to retrieve the next page of results. If you received a value for <code>NextToken</code> in the response from a previous <code>ListJournalS3Exports</code> call, then you should use that value as input here.
  ##   maxResults: int
  ##             : The maximum number of results to return in a single <code>ListJournalS3Exports</code> request. (The actual number of results returned might be fewer.)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_594217 = newJObject()
  add(query_594217, "NextToken", newJString(NextToken))
  add(query_594217, "next_token", newJString(nextToken))
  add(query_594217, "max_results", newJInt(maxResults))
  add(query_594217, "MaxResults", newJString(MaxResults))
  result = call_594216.call(nil, query_594217, nil, nil, nil)

var listJournalS3Exports* = Call_ListJournalS3Exports_594201(
    name: "listJournalS3Exports", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com", route: "/journal-s3-exports",
    validator: validate_ListJournalS3Exports_594202, base: "/",
    url: url_ListJournalS3Exports_594203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594232 = ref object of OpenApiRestCall_593437
proc url_TagResource_594234(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_TagResource_594233(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594235 = path.getOrDefault("resourceArn")
  valid_594235 = validateParameter(valid_594235, JString, required = true,
                                 default = nil)
  if valid_594235 != nil:
    section.add "resourceArn", valid_594235
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
  var valid_594236 = header.getOrDefault("X-Amz-Date")
  valid_594236 = validateParameter(valid_594236, JString, required = false,
                                 default = nil)
  if valid_594236 != nil:
    section.add "X-Amz-Date", valid_594236
  var valid_594237 = header.getOrDefault("X-Amz-Security-Token")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "X-Amz-Security-Token", valid_594237
  var valid_594238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "X-Amz-Content-Sha256", valid_594238
  var valid_594239 = header.getOrDefault("X-Amz-Algorithm")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Algorithm", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Signature")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Signature", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-SignedHeaders", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Credential")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Credential", valid_594242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594244: Call_TagResource_594232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to a specified Amazon QLDB resource.</p> <p>A resource can have up to 50 tags. If you try to create more than 50 tags for a resource, your request fails and returns an error.</p>
  ## 
  let valid = call_594244.validator(path, query, header, formData, body)
  let scheme = call_594244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594244.url(scheme.get, call_594244.host, call_594244.base,
                         call_594244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594244, url, valid)

proc call*(call_594245: Call_TagResource_594232; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## <p>Adds one or more tags to a specified Amazon QLDB resource.</p> <p>A resource can have up to 50 tags. If you try to create more than 50 tags for a resource, your request fails and returns an error.</p>
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) to which you want to add the tags. For example:</p> <p> <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> </p>
  var path_594246 = newJObject()
  var body_594247 = newJObject()
  if body != nil:
    body_594247 = body
  add(path_594246, "resourceArn", newJString(resourceArn))
  result = call_594245.call(path_594246, nil, nil, nil, body_594247)

var tagResource* = Call_TagResource_594232(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "qldb.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_594233,
                                        base: "/", url: url_TagResource_594234,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594218 = ref object of OpenApiRestCall_593437
proc url_ListTagsForResource_594220(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListTagsForResource_594219(path: JsonNode; query: JsonNode;
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
  var valid_594221 = path.getOrDefault("resourceArn")
  valid_594221 = validateParameter(valid_594221, JString, required = true,
                                 default = nil)
  if valid_594221 != nil:
    section.add "resourceArn", valid_594221
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
  var valid_594222 = header.getOrDefault("X-Amz-Date")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "X-Amz-Date", valid_594222
  var valid_594223 = header.getOrDefault("X-Amz-Security-Token")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "X-Amz-Security-Token", valid_594223
  var valid_594224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "X-Amz-Content-Sha256", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Algorithm")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Algorithm", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Signature")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Signature", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-SignedHeaders", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-Credential")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-Credential", valid_594228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594229: Call_ListTagsForResource_594218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tags for a specified Amazon QLDB resource.
  ## 
  let valid = call_594229.validator(path, query, header, formData, body)
  let scheme = call_594229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594229.url(scheme.get, call_594229.host, call_594229.base,
                         call_594229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594229, url, valid)

proc call*(call_594230: Call_ListTagsForResource_594218; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns all tags for a specified Amazon QLDB resource.
  ##   resourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) for which you want to list the tags. For example:</p> <p> <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> </p>
  var path_594231 = newJObject()
  add(path_594231, "resourceArn", newJString(resourceArn))
  result = call_594230.call(path_594231, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_594218(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_594219, base: "/",
    url: url_ListTagsForResource_594220, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594248 = ref object of OpenApiRestCall_593437
proc url_UntagResource_594250(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UntagResource_594249(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594251 = path.getOrDefault("resourceArn")
  valid_594251 = validateParameter(valid_594251, JString, required = true,
                                 default = nil)
  if valid_594251 != nil:
    section.add "resourceArn", valid_594251
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The list of tag keys that you want to remove.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_594252 = query.getOrDefault("tagKeys")
  valid_594252 = validateParameter(valid_594252, JArray, required = true, default = nil)
  if valid_594252 != nil:
    section.add "tagKeys", valid_594252
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
  var valid_594253 = header.getOrDefault("X-Amz-Date")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "X-Amz-Date", valid_594253
  var valid_594254 = header.getOrDefault("X-Amz-Security-Token")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-Security-Token", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Content-Sha256", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Algorithm")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Algorithm", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Signature")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Signature", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-SignedHeaders", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Credential")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Credential", valid_594259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594260: Call_UntagResource_594248; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a specified Amazon QLDB resource. You can specify up to 50 tag keys to remove.
  ## 
  let valid = call_594260.validator(path, query, header, formData, body)
  let scheme = call_594260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594260.url(scheme.get, call_594260.host, call_594260.base,
                         call_594260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594260, url, valid)

proc call*(call_594261: Call_UntagResource_594248; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes one or more tags from a specified Amazon QLDB resource. You can specify up to 50 tag keys to remove.
  ##   tagKeys: JArray (required)
  ##          : The list of tag keys that you want to remove.
  ##   resourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) from which you want to remove the tags. For example:</p> <p> <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> </p>
  var path_594262 = newJObject()
  var query_594263 = newJObject()
  if tagKeys != nil:
    query_594263.add "tagKeys", tagKeys
  add(path_594262, "resourceArn", newJString(resourceArn))
  result = call_594261.call(path_594262, query_594263, nil, nil, nil)

var untagResource* = Call_UntagResource_594248(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "qldb.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_594249,
    base: "/", url: url_UntagResource_594250, schemes: {Scheme.Https, Scheme.Http})
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
