
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
  Call_CreateLedger_603062 = ref object of OpenApiRestCall_602466
proc url_CreateLedger_603064(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateLedger_603063(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603065 = header.getOrDefault("X-Amz-Date")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Date", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Security-Token")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Security-Token", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Content-Sha256", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Algorithm")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Algorithm", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Signature")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Signature", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-SignedHeaders", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Credential")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Credential", valid_603071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603073: Call_CreateLedger_603062; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new ledger in your AWS account.
  ## 
  let valid = call_603073.validator(path, query, header, formData, body)
  let scheme = call_603073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603073.url(scheme.get, call_603073.host, call_603073.base,
                         call_603073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603073, url, valid)

proc call*(call_603074: Call_CreateLedger_603062; body: JsonNode): Recallable =
  ## createLedger
  ## Creates a new ledger in your AWS account.
  ##   body: JObject (required)
  var body_603075 = newJObject()
  if body != nil:
    body_603075 = body
  result = call_603074.call(nil, nil, nil, nil, body_603075)

var createLedger* = Call_CreateLedger_603062(name: "createLedger",
    meth: HttpMethod.HttpPost, host: "qldb.amazonaws.com", route: "/ledgers",
    validator: validate_CreateLedger_603063, base: "/", url: url_CreateLedger_603064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLedgers_602803 = ref object of OpenApiRestCall_602466
proc url_ListLedgers_602805(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLedgers_602804(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602917 = query.getOrDefault("NextToken")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "NextToken", valid_602917
  var valid_602918 = query.getOrDefault("next_token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "next_token", valid_602918
  var valid_602919 = query.getOrDefault("max_results")
  valid_602919 = validateParameter(valid_602919, JInt, required = false, default = nil)
  if valid_602919 != nil:
    section.add "max_results", valid_602919
  var valid_602920 = query.getOrDefault("MaxResults")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "MaxResults", valid_602920
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
  var valid_602921 = header.getOrDefault("X-Amz-Date")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-Date", valid_602921
  var valid_602922 = header.getOrDefault("X-Amz-Security-Token")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "X-Amz-Security-Token", valid_602922
  var valid_602923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "X-Amz-Content-Sha256", valid_602923
  var valid_602924 = header.getOrDefault("X-Amz-Algorithm")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-Algorithm", valid_602924
  var valid_602925 = header.getOrDefault("X-Amz-Signature")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "X-Amz-Signature", valid_602925
  var valid_602926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "X-Amz-SignedHeaders", valid_602926
  var valid_602927 = header.getOrDefault("X-Amz-Credential")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "X-Amz-Credential", valid_602927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602950: Call_ListLedgers_602803; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an array of ledger summaries that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of 100 items and is paginated so that you can retrieve all the items by calling <code>ListLedgers</code> multiple times.</p>
  ## 
  let valid = call_602950.validator(path, query, header, formData, body)
  let scheme = call_602950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602950.url(scheme.get, call_602950.host, call_602950.base,
                         call_602950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602950, url, valid)

proc call*(call_603021: Call_ListLedgers_602803; NextToken: string = "";
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
  var query_603022 = newJObject()
  add(query_603022, "NextToken", newJString(NextToken))
  add(query_603022, "next_token", newJString(nextToken))
  add(query_603022, "max_results", newJInt(maxResults))
  add(query_603022, "MaxResults", newJString(MaxResults))
  result = call_603021.call(nil, query_603022, nil, nil, nil)

var listLedgers* = Call_ListLedgers_602803(name: "listLedgers",
                                        meth: HttpMethod.HttpGet,
                                        host: "qldb.amazonaws.com",
                                        route: "/ledgers",
                                        validator: validate_ListLedgers_602804,
                                        base: "/", url: url_ListLedgers_602805,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLedger_603076 = ref object of OpenApiRestCall_602466
proc url_DescribeLedger_603078(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeLedger_603077(path: JsonNode; query: JsonNode;
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
  var valid_603093 = path.getOrDefault("name")
  valid_603093 = validateParameter(valid_603093, JString, required = true,
                                 default = nil)
  if valid_603093 != nil:
    section.add "name", valid_603093
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
  var valid_603094 = header.getOrDefault("X-Amz-Date")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Date", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Security-Token")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Security-Token", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Content-Sha256", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Algorithm")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Algorithm", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Signature")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Signature", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-SignedHeaders", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Credential")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Credential", valid_603100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603101: Call_DescribeLedger_603076; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a ledger, including its state and when it was created.
  ## 
  let valid = call_603101.validator(path, query, header, formData, body)
  let scheme = call_603101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603101.url(scheme.get, call_603101.host, call_603101.base,
                         call_603101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603101, url, valid)

proc call*(call_603102: Call_DescribeLedger_603076; name: string): Recallable =
  ## describeLedger
  ## Returns information about a ledger, including its state and when it was created.
  ##   name: string (required)
  ##       : The name of the ledger that you want to describe.
  var path_603103 = newJObject()
  add(path_603103, "name", newJString(name))
  result = call_603102.call(path_603103, nil, nil, nil, nil)

var describeLedger* = Call_DescribeLedger_603076(name: "describeLedger",
    meth: HttpMethod.HttpGet, host: "qldb.amazonaws.com", route: "/ledgers/{name}",
    validator: validate_DescribeLedger_603077, base: "/", url: url_DescribeLedger_603078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLedger_603118 = ref object of OpenApiRestCall_602466
proc url_UpdateLedger_603120(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateLedger_603119(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603121 = path.getOrDefault("name")
  valid_603121 = validateParameter(valid_603121, JString, required = true,
                                 default = nil)
  if valid_603121 != nil:
    section.add "name", valid_603121
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
  var valid_603122 = header.getOrDefault("X-Amz-Date")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Date", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Security-Token")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Security-Token", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Content-Sha256", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Algorithm")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Algorithm", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Signature")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Signature", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-SignedHeaders", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Credential")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Credential", valid_603128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603130: Call_UpdateLedger_603118; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates properties on a ledger.
  ## 
  let valid = call_603130.validator(path, query, header, formData, body)
  let scheme = call_603130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603130.url(scheme.get, call_603130.host, call_603130.base,
                         call_603130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603130, url, valid)

proc call*(call_603131: Call_UpdateLedger_603118; name: string; body: JsonNode): Recallable =
  ## updateLedger
  ## Updates properties on a ledger.
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_603132 = newJObject()
  var body_603133 = newJObject()
  add(path_603132, "name", newJString(name))
  if body != nil:
    body_603133 = body
  result = call_603131.call(path_603132, nil, nil, nil, body_603133)

var updateLedger* = Call_UpdateLedger_603118(name: "updateLedger",
    meth: HttpMethod.HttpPatch, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}", validator: validate_UpdateLedger_603119, base: "/",
    url: url_UpdateLedger_603120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLedger_603104 = ref object of OpenApiRestCall_602466
proc url_DeleteLedger_603106(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLedger_603105(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603107 = path.getOrDefault("name")
  valid_603107 = validateParameter(valid_603107, JString, required = true,
                                 default = nil)
  if valid_603107 != nil:
    section.add "name", valid_603107
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
  var valid_603108 = header.getOrDefault("X-Amz-Date")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Date", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Security-Token")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Security-Token", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Content-Sha256", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-Algorithm")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Algorithm", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Signature")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Signature", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-SignedHeaders", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-Credential")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Credential", valid_603114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603115: Call_DeleteLedger_603104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a ledger and all of its contents. This action is irreversible.</p> <p>If deletion protection is enabled, you must first disable it before you can delete the ledger using the QLDB API or the AWS Command Line Interface (AWS CLI). You can disable it by calling the <code>UpdateLedger</code> operation to set the flag to <code>false</code>. The QLDB console disables deletion protection for you when you use it to delete a ledger.</p>
  ## 
  let valid = call_603115.validator(path, query, header, formData, body)
  let scheme = call_603115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603115.url(scheme.get, call_603115.host, call_603115.base,
                         call_603115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603115, url, valid)

proc call*(call_603116: Call_DeleteLedger_603104; name: string): Recallable =
  ## deleteLedger
  ## <p>Deletes a ledger and all of its contents. This action is irreversible.</p> <p>If deletion protection is enabled, you must first disable it before you can delete the ledger using the QLDB API or the AWS Command Line Interface (AWS CLI). You can disable it by calling the <code>UpdateLedger</code> operation to set the flag to <code>false</code>. The QLDB console disables deletion protection for you when you use it to delete a ledger.</p>
  ##   name: string (required)
  ##       : The name of the ledger that you want to delete.
  var path_603117 = newJObject()
  add(path_603117, "name", newJString(name))
  result = call_603116.call(path_603117, nil, nil, nil, nil)

var deleteLedger* = Call_DeleteLedger_603104(name: "deleteLedger",
    meth: HttpMethod.HttpDelete, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}", validator: validate_DeleteLedger_603105, base: "/",
    url: url_DeleteLedger_603106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJournalS3Export_603134 = ref object of OpenApiRestCall_602466
proc url_DescribeJournalS3Export_603136(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeJournalS3Export_603135(path: JsonNode; query: JsonNode;
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
  var valid_603137 = path.getOrDefault("name")
  valid_603137 = validateParameter(valid_603137, JString, required = true,
                                 default = nil)
  if valid_603137 != nil:
    section.add "name", valid_603137
  var valid_603138 = path.getOrDefault("exportId")
  valid_603138 = validateParameter(valid_603138, JString, required = true,
                                 default = nil)
  if valid_603138 != nil:
    section.add "exportId", valid_603138
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
  var valid_603139 = header.getOrDefault("X-Amz-Date")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Date", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Security-Token")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Security-Token", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Content-Sha256", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Algorithm")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Algorithm", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Signature")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Signature", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-SignedHeaders", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Credential")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Credential", valid_603145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603146: Call_DescribeJournalS3Export_603134; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a journal export job, including the ledger name, export ID, when it was created, current status, and its start and end time export parameters.</p> <p>If the export job with the given <code>ExportId</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p>
  ## 
  let valid = call_603146.validator(path, query, header, formData, body)
  let scheme = call_603146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603146.url(scheme.get, call_603146.host, call_603146.base,
                         call_603146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603146, url, valid)

proc call*(call_603147: Call_DescribeJournalS3Export_603134; name: string;
          exportId: string): Recallable =
  ## describeJournalS3Export
  ## <p>Returns information about a journal export job, including the ledger name, export ID, when it was created, current status, and its start and end time export parameters.</p> <p>If the export job with the given <code>ExportId</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p>
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   exportId: string (required)
  ##           : The unique ID of the journal export job that you want to describe.
  var path_603148 = newJObject()
  add(path_603148, "name", newJString(name))
  add(path_603148, "exportId", newJString(exportId))
  result = call_603147.call(path_603148, nil, nil, nil, nil)

var describeJournalS3Export* = Call_DescribeJournalS3Export_603134(
    name: "describeJournalS3Export", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com",
    route: "/ledgers/{name}/journal-s3-exports/{exportId}",
    validator: validate_DescribeJournalS3Export_603135, base: "/",
    url: url_DescribeJournalS3Export_603136, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportJournalToS3_603168 = ref object of OpenApiRestCall_602466
proc url_ExportJournalToS3_603170(protocol: Scheme; host: string; base: string;
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

proc validate_ExportJournalToS3_603169(path: JsonNode; query: JsonNode;
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
  var valid_603171 = path.getOrDefault("name")
  valid_603171 = validateParameter(valid_603171, JString, required = true,
                                 default = nil)
  if valid_603171 != nil:
    section.add "name", valid_603171
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
  var valid_603172 = header.getOrDefault("X-Amz-Date")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Date", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Security-Token")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Security-Token", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Content-Sha256", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-Algorithm")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Algorithm", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Signature")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Signature", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-SignedHeaders", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Credential")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Credential", valid_603178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603180: Call_ExportJournalToS3_603168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Exports journal contents within a date and time range from a ledger into a specified Amazon Simple Storage Service (Amazon S3) bucket. The data is written as files in Amazon Ion format.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>You can initiate up to two concurrent journal export requests for each ledger. Beyond this limit, journal export requests throw <code>LimitExceededException</code>.</p>
  ## 
  let valid = call_603180.validator(path, query, header, formData, body)
  let scheme = call_603180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603180.url(scheme.get, call_603180.host, call_603180.base,
                         call_603180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603180, url, valid)

proc call*(call_603181: Call_ExportJournalToS3_603168; name: string; body: JsonNode): Recallable =
  ## exportJournalToS3
  ## <p>Exports journal contents within a date and time range from a ledger into a specified Amazon Simple Storage Service (Amazon S3) bucket. The data is written as files in Amazon Ion format.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>You can initiate up to two concurrent journal export requests for each ledger. Beyond this limit, journal export requests throw <code>LimitExceededException</code>.</p>
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_603182 = newJObject()
  var body_603183 = newJObject()
  add(path_603182, "name", newJString(name))
  if body != nil:
    body_603183 = body
  result = call_603181.call(path_603182, nil, nil, nil, body_603183)

var exportJournalToS3* = Call_ExportJournalToS3_603168(name: "exportJournalToS3",
    meth: HttpMethod.HttpPost, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}/journal-s3-exports",
    validator: validate_ExportJournalToS3_603169, base: "/",
    url: url_ExportJournalToS3_603170, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJournalS3ExportsForLedger_603149 = ref object of OpenApiRestCall_602466
proc url_ListJournalS3ExportsForLedger_603151(protocol: Scheme; host: string;
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

proc validate_ListJournalS3ExportsForLedger_603150(path: JsonNode; query: JsonNode;
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
  var valid_603152 = path.getOrDefault("name")
  valid_603152 = validateParameter(valid_603152, JString, required = true,
                                 default = nil)
  if valid_603152 != nil:
    section.add "name", valid_603152
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
  var valid_603153 = query.getOrDefault("NextToken")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "NextToken", valid_603153
  var valid_603154 = query.getOrDefault("next_token")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "next_token", valid_603154
  var valid_603155 = query.getOrDefault("max_results")
  valid_603155 = validateParameter(valid_603155, JInt, required = false, default = nil)
  if valid_603155 != nil:
    section.add "max_results", valid_603155
  var valid_603156 = query.getOrDefault("MaxResults")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "MaxResults", valid_603156
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
  var valid_603157 = header.getOrDefault("X-Amz-Date")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Date", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Security-Token")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Security-Token", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-Content-Sha256", valid_603159
  var valid_603160 = header.getOrDefault("X-Amz-Algorithm")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-Algorithm", valid_603160
  var valid_603161 = header.getOrDefault("X-Amz-Signature")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-Signature", valid_603161
  var valid_603162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-SignedHeaders", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Credential")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Credential", valid_603163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603164: Call_ListJournalS3ExportsForLedger_603149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an array of journal export job descriptions for a specified ledger.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3ExportsForLedger</code> multiple times.</p>
  ## 
  let valid = call_603164.validator(path, query, header, formData, body)
  let scheme = call_603164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603164.url(scheme.get, call_603164.host, call_603164.base,
                         call_603164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603164, url, valid)

proc call*(call_603165: Call_ListJournalS3ExportsForLedger_603149; name: string;
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
  var path_603166 = newJObject()
  var query_603167 = newJObject()
  add(path_603166, "name", newJString(name))
  add(query_603167, "NextToken", newJString(NextToken))
  add(query_603167, "next_token", newJString(nextToken))
  add(query_603167, "max_results", newJInt(maxResults))
  add(query_603167, "MaxResults", newJString(MaxResults))
  result = call_603165.call(path_603166, query_603167, nil, nil, nil)

var listJournalS3ExportsForLedger* = Call_ListJournalS3ExportsForLedger_603149(
    name: "listJournalS3ExportsForLedger", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com", route: "/ledgers/{name}/journal-s3-exports",
    validator: validate_ListJournalS3ExportsForLedger_603150, base: "/",
    url: url_ListJournalS3ExportsForLedger_603151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlock_603184 = ref object of OpenApiRestCall_602466
proc url_GetBlock_603186(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetBlock_603185(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603187 = path.getOrDefault("name")
  valid_603187 = validateParameter(valid_603187, JString, required = true,
                                 default = nil)
  if valid_603187 != nil:
    section.add "name", valid_603187
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
  var valid_603188 = header.getOrDefault("X-Amz-Date")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Date", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Security-Token")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Security-Token", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Content-Sha256", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Algorithm")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Algorithm", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Signature")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Signature", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-SignedHeaders", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-Credential")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Credential", valid_603194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603196: Call_GetBlock_603184; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a journal block object at a specified address in a ledger. Also returns a proof of the specified block for verification if <code>DigestTipAddress</code> is provided.</p> <p>If the specified ledger doesn't exist or is in <code>DELETING</code> status, then throws <code>ResourceNotFoundException</code>.</p> <p>If the specified ledger is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>If no block exists with the specified address, then throws <code>InvalidParameterException</code>.</p>
  ## 
  let valid = call_603196.validator(path, query, header, formData, body)
  let scheme = call_603196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603196.url(scheme.get, call_603196.host, call_603196.base,
                         call_603196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603196, url, valid)

proc call*(call_603197: Call_GetBlock_603184; name: string; body: JsonNode): Recallable =
  ## getBlock
  ## <p>Returns a journal block object at a specified address in a ledger. Also returns a proof of the specified block for verification if <code>DigestTipAddress</code> is provided.</p> <p>If the specified ledger doesn't exist or is in <code>DELETING</code> status, then throws <code>ResourceNotFoundException</code>.</p> <p>If the specified ledger is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>If no block exists with the specified address, then throws <code>InvalidParameterException</code>.</p>
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_603198 = newJObject()
  var body_603199 = newJObject()
  add(path_603198, "name", newJString(name))
  if body != nil:
    body_603199 = body
  result = call_603197.call(path_603198, nil, nil, nil, body_603199)

var getBlock* = Call_GetBlock_603184(name: "getBlock", meth: HttpMethod.HttpPost,
                                  host: "qldb.amazonaws.com",
                                  route: "/ledgers/{name}/block",
                                  validator: validate_GetBlock_603185, base: "/",
                                  url: url_GetBlock_603186,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDigest_603200 = ref object of OpenApiRestCall_602466
proc url_GetDigest_603202(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetDigest_603201(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603203 = path.getOrDefault("name")
  valid_603203 = validateParameter(valid_603203, JString, required = true,
                                 default = nil)
  if valid_603203 != nil:
    section.add "name", valid_603203
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
  var valid_603204 = header.getOrDefault("X-Amz-Date")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Date", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Security-Token")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Security-Token", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Content-Sha256", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Algorithm")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Algorithm", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Signature")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Signature", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-SignedHeaders", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-Credential")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Credential", valid_603210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603211: Call_GetDigest_603200; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the digest of a ledger at the latest committed block in the journal. The response includes a 256-bit hash value and a block address.
  ## 
  let valid = call_603211.validator(path, query, header, formData, body)
  let scheme = call_603211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603211.url(scheme.get, call_603211.host, call_603211.base,
                         call_603211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603211, url, valid)

proc call*(call_603212: Call_GetDigest_603200; name: string): Recallable =
  ## getDigest
  ## Returns the digest of a ledger at the latest committed block in the journal. The response includes a 256-bit hash value and a block address.
  ##   name: string (required)
  ##       : The name of the ledger.
  var path_603213 = newJObject()
  add(path_603213, "name", newJString(name))
  result = call_603212.call(path_603213, nil, nil, nil, nil)

var getDigest* = Call_GetDigest_603200(name: "getDigest", meth: HttpMethod.HttpPost,
                                    host: "qldb.amazonaws.com",
                                    route: "/ledgers/{name}/digest",
                                    validator: validate_GetDigest_603201,
                                    base: "/", url: url_GetDigest_603202,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevision_603214 = ref object of OpenApiRestCall_602466
proc url_GetRevision_603216(protocol: Scheme; host: string; base: string;
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

proc validate_GetRevision_603215(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603217 = path.getOrDefault("name")
  valid_603217 = validateParameter(valid_603217, JString, required = true,
                                 default = nil)
  if valid_603217 != nil:
    section.add "name", valid_603217
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
  var valid_603218 = header.getOrDefault("X-Amz-Date")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Date", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-Security-Token")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Security-Token", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Content-Sha256", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Algorithm")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Algorithm", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-Signature")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Signature", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-SignedHeaders", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-Credential")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Credential", valid_603224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603226: Call_GetRevision_603214; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a revision data object for a specified document ID and block address. Also returns a proof of the specified revision for verification if <code>DigestTipAddress</code> is provided.
  ## 
  let valid = call_603226.validator(path, query, header, formData, body)
  let scheme = call_603226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603226.url(scheme.get, call_603226.host, call_603226.base,
                         call_603226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603226, url, valid)

proc call*(call_603227: Call_GetRevision_603214; name: string; body: JsonNode): Recallable =
  ## getRevision
  ## Returns a revision data object for a specified document ID and block address. Also returns a proof of the specified revision for verification if <code>DigestTipAddress</code> is provided.
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_603228 = newJObject()
  var body_603229 = newJObject()
  add(path_603228, "name", newJString(name))
  if body != nil:
    body_603229 = body
  result = call_603227.call(path_603228, nil, nil, nil, body_603229)

var getRevision* = Call_GetRevision_603214(name: "getRevision",
                                        meth: HttpMethod.HttpPost,
                                        host: "qldb.amazonaws.com",
                                        route: "/ledgers/{name}/revision",
                                        validator: validate_GetRevision_603215,
                                        base: "/", url: url_GetRevision_603216,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJournalS3Exports_603230 = ref object of OpenApiRestCall_602466
proc url_ListJournalS3Exports_603232(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListJournalS3Exports_603231(path: JsonNode; query: JsonNode;
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
  var valid_603233 = query.getOrDefault("NextToken")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "NextToken", valid_603233
  var valid_603234 = query.getOrDefault("next_token")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "next_token", valid_603234
  var valid_603235 = query.getOrDefault("max_results")
  valid_603235 = validateParameter(valid_603235, JInt, required = false, default = nil)
  if valid_603235 != nil:
    section.add "max_results", valid_603235
  var valid_603236 = query.getOrDefault("MaxResults")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "MaxResults", valid_603236
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
  var valid_603237 = header.getOrDefault("X-Amz-Date")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Date", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Security-Token")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Security-Token", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Content-Sha256", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Algorithm")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Algorithm", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Signature")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Signature", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-SignedHeaders", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Credential")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Credential", valid_603243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603244: Call_ListJournalS3Exports_603230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an array of journal export job descriptions for all ledgers that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3Exports</code> multiple times.</p>
  ## 
  let valid = call_603244.validator(path, query, header, formData, body)
  let scheme = call_603244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603244.url(scheme.get, call_603244.host, call_603244.base,
                         call_603244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603244, url, valid)

proc call*(call_603245: Call_ListJournalS3Exports_603230; NextToken: string = "";
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
  var query_603246 = newJObject()
  add(query_603246, "NextToken", newJString(NextToken))
  add(query_603246, "next_token", newJString(nextToken))
  add(query_603246, "max_results", newJInt(maxResults))
  add(query_603246, "MaxResults", newJString(MaxResults))
  result = call_603245.call(nil, query_603246, nil, nil, nil)

var listJournalS3Exports* = Call_ListJournalS3Exports_603230(
    name: "listJournalS3Exports", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com", route: "/journal-s3-exports",
    validator: validate_ListJournalS3Exports_603231, base: "/",
    url: url_ListJournalS3Exports_603232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603261 = ref object of OpenApiRestCall_602466
proc url_TagResource_603263(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_603262(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603264 = path.getOrDefault("resourceArn")
  valid_603264 = validateParameter(valid_603264, JString, required = true,
                                 default = nil)
  if valid_603264 != nil:
    section.add "resourceArn", valid_603264
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
  var valid_603265 = header.getOrDefault("X-Amz-Date")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Date", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-Security-Token")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Security-Token", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Content-Sha256", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Algorithm")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Algorithm", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Signature")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Signature", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-SignedHeaders", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Credential")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Credential", valid_603271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603273: Call_TagResource_603261; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to a specified Amazon QLDB resource.</p> <p>A resource can have up to 50 tags. If you try to create more than 50 tags for a resource, your request fails and returns an error.</p>
  ## 
  let valid = call_603273.validator(path, query, header, formData, body)
  let scheme = call_603273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603273.url(scheme.get, call_603273.host, call_603273.base,
                         call_603273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603273, url, valid)

proc call*(call_603274: Call_TagResource_603261; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## <p>Adds one or more tags to a specified Amazon QLDB resource.</p> <p>A resource can have up to 50 tags. If you try to create more than 50 tags for a resource, your request fails and returns an error.</p>
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) to which you want to add the tags. For example:</p> <p> <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> </p>
  var path_603275 = newJObject()
  var body_603276 = newJObject()
  if body != nil:
    body_603276 = body
  add(path_603275, "resourceArn", newJString(resourceArn))
  result = call_603274.call(path_603275, nil, nil, nil, body_603276)

var tagResource* = Call_TagResource_603261(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "qldb.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_603262,
                                        base: "/", url: url_TagResource_603263,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603247 = ref object of OpenApiRestCall_602466
proc url_ListTagsForResource_603249(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_603248(path: JsonNode; query: JsonNode;
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
  var valid_603250 = path.getOrDefault("resourceArn")
  valid_603250 = validateParameter(valid_603250, JString, required = true,
                                 default = nil)
  if valid_603250 != nil:
    section.add "resourceArn", valid_603250
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
  var valid_603251 = header.getOrDefault("X-Amz-Date")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Date", valid_603251
  var valid_603252 = header.getOrDefault("X-Amz-Security-Token")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Security-Token", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Content-Sha256", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Algorithm")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Algorithm", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Signature")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Signature", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-SignedHeaders", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Credential")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Credential", valid_603257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603258: Call_ListTagsForResource_603247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tags for a specified Amazon QLDB resource.
  ## 
  let valid = call_603258.validator(path, query, header, formData, body)
  let scheme = call_603258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603258.url(scheme.get, call_603258.host, call_603258.base,
                         call_603258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603258, url, valid)

proc call*(call_603259: Call_ListTagsForResource_603247; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns all tags for a specified Amazon QLDB resource.
  ##   resourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) for which you want to list the tags. For example:</p> <p> <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> </p>
  var path_603260 = newJObject()
  add(path_603260, "resourceArn", newJString(resourceArn))
  result = call_603259.call(path_603260, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_603247(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_603248, base: "/",
    url: url_ListTagsForResource_603249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_603277 = ref object of OpenApiRestCall_602466
proc url_UntagResource_603279(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_603278(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603280 = path.getOrDefault("resourceArn")
  valid_603280 = validateParameter(valid_603280, JString, required = true,
                                 default = nil)
  if valid_603280 != nil:
    section.add "resourceArn", valid_603280
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The list of tag keys that you want to remove.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_603281 = query.getOrDefault("tagKeys")
  valid_603281 = validateParameter(valid_603281, JArray, required = true, default = nil)
  if valid_603281 != nil:
    section.add "tagKeys", valid_603281
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
  var valid_603282 = header.getOrDefault("X-Amz-Date")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Date", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Security-Token")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Security-Token", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Content-Sha256", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Algorithm")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Algorithm", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Signature")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Signature", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-SignedHeaders", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Credential")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Credential", valid_603288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603289: Call_UntagResource_603277; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a specified Amazon QLDB resource. You can specify up to 50 tag keys to remove.
  ## 
  let valid = call_603289.validator(path, query, header, formData, body)
  let scheme = call_603289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603289.url(scheme.get, call_603289.host, call_603289.base,
                         call_603289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603289, url, valid)

proc call*(call_603290: Call_UntagResource_603277; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes one or more tags from a specified Amazon QLDB resource. You can specify up to 50 tag keys to remove.
  ##   tagKeys: JArray (required)
  ##          : The list of tag keys that you want to remove.
  ##   resourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) from which you want to remove the tags. For example:</p> <p> <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> </p>
  var path_603291 = newJObject()
  var query_603292 = newJObject()
  if tagKeys != nil:
    query_603292.add "tagKeys", tagKeys
  add(path_603291, "resourceArn", newJString(resourceArn))
  result = call_603290.call(path_603291, query_603292, nil, nil, nil)

var untagResource* = Call_UntagResource_603277(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "qldb.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_603278,
    base: "/", url: url_UntagResource_603279, schemes: {Scheme.Https, Scheme.Http})
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
