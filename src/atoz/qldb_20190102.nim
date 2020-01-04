
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
  Call_CreateLedger_601986 = ref object of OpenApiRestCall_601389
proc url_CreateLedger_601988(protocol: Scheme; host: string; base: string;
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

proc validate_CreateLedger_601987(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601989 = header.getOrDefault("X-Amz-Signature")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-Signature", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Content-Sha256", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Date")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Date", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Credential")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Credential", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-Security-Token")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-Security-Token", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-Algorithm")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Algorithm", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-SignedHeaders", valid_601995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601997: Call_CreateLedger_601986; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new ledger in your AWS account.
  ## 
  let valid = call_601997.validator(path, query, header, formData, body)
  let scheme = call_601997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601997.url(scheme.get, call_601997.host, call_601997.base,
                         call_601997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601997, url, valid)

proc call*(call_601998: Call_CreateLedger_601986; body: JsonNode): Recallable =
  ## createLedger
  ## Creates a new ledger in your AWS account.
  ##   body: JObject (required)
  var body_601999 = newJObject()
  if body != nil:
    body_601999 = body
  result = call_601998.call(nil, nil, nil, nil, body_601999)

var createLedger* = Call_CreateLedger_601986(name: "createLedger",
    meth: HttpMethod.HttpPost, host: "qldb.amazonaws.com", route: "/ledgers",
    validator: validate_CreateLedger_601987, base: "/", url: url_CreateLedger_601988,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLedgers_601727 = ref object of OpenApiRestCall_601389
proc url_ListLedgers_601729(protocol: Scheme; host: string; base: string;
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

proc validate_ListLedgers_601728(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601841 = query.getOrDefault("MaxResults")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "MaxResults", valid_601841
  var valid_601842 = query.getOrDefault("NextToken")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "NextToken", valid_601842
  var valid_601843 = query.getOrDefault("next_token")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "next_token", valid_601843
  var valid_601844 = query.getOrDefault("max_results")
  valid_601844 = validateParameter(valid_601844, JInt, required = false, default = nil)
  if valid_601844 != nil:
    section.add "max_results", valid_601844
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
  var valid_601845 = header.getOrDefault("X-Amz-Signature")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Signature", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Content-Sha256", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Date")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Date", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Credential")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Credential", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-Security-Token")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-Security-Token", valid_601849
  var valid_601850 = header.getOrDefault("X-Amz-Algorithm")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Algorithm", valid_601850
  var valid_601851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "X-Amz-SignedHeaders", valid_601851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601874: Call_ListLedgers_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an array of ledger summaries that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of 100 items and is paginated so that you can retrieve all the items by calling <code>ListLedgers</code> multiple times.</p>
  ## 
  let valid = call_601874.validator(path, query, header, formData, body)
  let scheme = call_601874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601874.url(scheme.get, call_601874.host, call_601874.base,
                         call_601874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601874, url, valid)

proc call*(call_601945: Call_ListLedgers_601727; MaxResults: string = "";
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
  var query_601946 = newJObject()
  add(query_601946, "MaxResults", newJString(MaxResults))
  add(query_601946, "NextToken", newJString(NextToken))
  add(query_601946, "next_token", newJString(nextToken))
  add(query_601946, "max_results", newJInt(maxResults))
  result = call_601945.call(nil, query_601946, nil, nil, nil)

var listLedgers* = Call_ListLedgers_601727(name: "listLedgers",
                                        meth: HttpMethod.HttpGet,
                                        host: "qldb.amazonaws.com",
                                        route: "/ledgers",
                                        validator: validate_ListLedgers_601728,
                                        base: "/", url: url_ListLedgers_601729,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLedger_602000 = ref object of OpenApiRestCall_601389
proc url_DescribeLedger_602002(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeLedger_602001(path: JsonNode; query: JsonNode;
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
  var valid_602017 = path.getOrDefault("name")
  valid_602017 = validateParameter(valid_602017, JString, required = true,
                                 default = nil)
  if valid_602017 != nil:
    section.add "name", valid_602017
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
  var valid_602018 = header.getOrDefault("X-Amz-Signature")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Signature", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Content-Sha256", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Date")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Date", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Credential")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Credential", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Security-Token")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Security-Token", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Algorithm")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Algorithm", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-SignedHeaders", valid_602024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602025: Call_DescribeLedger_602000; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a ledger, including its state and when it was created.
  ## 
  let valid = call_602025.validator(path, query, header, formData, body)
  let scheme = call_602025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602025.url(scheme.get, call_602025.host, call_602025.base,
                         call_602025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602025, url, valid)

proc call*(call_602026: Call_DescribeLedger_602000; name: string): Recallable =
  ## describeLedger
  ## Returns information about a ledger, including its state and when it was created.
  ##   name: string (required)
  ##       : The name of the ledger that you want to describe.
  var path_602027 = newJObject()
  add(path_602027, "name", newJString(name))
  result = call_602026.call(path_602027, nil, nil, nil, nil)

var describeLedger* = Call_DescribeLedger_602000(name: "describeLedger",
    meth: HttpMethod.HttpGet, host: "qldb.amazonaws.com", route: "/ledgers/{name}",
    validator: validate_DescribeLedger_602001, base: "/", url: url_DescribeLedger_602002,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLedger_602042 = ref object of OpenApiRestCall_601389
proc url_UpdateLedger_602044(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateLedger_602043(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602045 = path.getOrDefault("name")
  valid_602045 = validateParameter(valid_602045, JString, required = true,
                                 default = nil)
  if valid_602045 != nil:
    section.add "name", valid_602045
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
  var valid_602046 = header.getOrDefault("X-Amz-Signature")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Signature", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Content-Sha256", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Date")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Date", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Credential")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Credential", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Security-Token")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Security-Token", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Algorithm")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Algorithm", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-SignedHeaders", valid_602052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602054: Call_UpdateLedger_602042; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates properties on a ledger.
  ## 
  let valid = call_602054.validator(path, query, header, formData, body)
  let scheme = call_602054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602054.url(scheme.get, call_602054.host, call_602054.base,
                         call_602054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602054, url, valid)

proc call*(call_602055: Call_UpdateLedger_602042; name: string; body: JsonNode): Recallable =
  ## updateLedger
  ## Updates properties on a ledger.
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_602056 = newJObject()
  var body_602057 = newJObject()
  add(path_602056, "name", newJString(name))
  if body != nil:
    body_602057 = body
  result = call_602055.call(path_602056, nil, nil, nil, body_602057)

var updateLedger* = Call_UpdateLedger_602042(name: "updateLedger",
    meth: HttpMethod.HttpPatch, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}", validator: validate_UpdateLedger_602043, base: "/",
    url: url_UpdateLedger_602044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLedger_602028 = ref object of OpenApiRestCall_601389
proc url_DeleteLedger_602030(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteLedger_602029(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602031 = path.getOrDefault("name")
  valid_602031 = validateParameter(valid_602031, JString, required = true,
                                 default = nil)
  if valid_602031 != nil:
    section.add "name", valid_602031
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
  var valid_602032 = header.getOrDefault("X-Amz-Signature")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Signature", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Content-Sha256", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Date")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Date", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Credential")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Credential", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Security-Token")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Security-Token", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Algorithm")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Algorithm", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-SignedHeaders", valid_602038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602039: Call_DeleteLedger_602028; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a ledger and all of its contents. This action is irreversible.</p> <p>If deletion protection is enabled, you must first disable it before you can delete the ledger using the QLDB API or the AWS Command Line Interface (AWS CLI). You can disable it by calling the <code>UpdateLedger</code> operation to set the flag to <code>false</code>. The QLDB console disables deletion protection for you when you use it to delete a ledger.</p>
  ## 
  let valid = call_602039.validator(path, query, header, formData, body)
  let scheme = call_602039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602039.url(scheme.get, call_602039.host, call_602039.base,
                         call_602039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602039, url, valid)

proc call*(call_602040: Call_DeleteLedger_602028; name: string): Recallable =
  ## deleteLedger
  ## <p>Deletes a ledger and all of its contents. This action is irreversible.</p> <p>If deletion protection is enabled, you must first disable it before you can delete the ledger using the QLDB API or the AWS Command Line Interface (AWS CLI). You can disable it by calling the <code>UpdateLedger</code> operation to set the flag to <code>false</code>. The QLDB console disables deletion protection for you when you use it to delete a ledger.</p>
  ##   name: string (required)
  ##       : The name of the ledger that you want to delete.
  var path_602041 = newJObject()
  add(path_602041, "name", newJString(name))
  result = call_602040.call(path_602041, nil, nil, nil, nil)

var deleteLedger* = Call_DeleteLedger_602028(name: "deleteLedger",
    meth: HttpMethod.HttpDelete, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}", validator: validate_DeleteLedger_602029, base: "/",
    url: url_DeleteLedger_602030, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJournalS3Export_602058 = ref object of OpenApiRestCall_601389
proc url_DescribeJournalS3Export_602060(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeJournalS3Export_602059(path: JsonNode; query: JsonNode;
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
  var valid_602061 = path.getOrDefault("exportId")
  valid_602061 = validateParameter(valid_602061, JString, required = true,
                                 default = nil)
  if valid_602061 != nil:
    section.add "exportId", valid_602061
  var valid_602062 = path.getOrDefault("name")
  valid_602062 = validateParameter(valid_602062, JString, required = true,
                                 default = nil)
  if valid_602062 != nil:
    section.add "name", valid_602062
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
  var valid_602063 = header.getOrDefault("X-Amz-Signature")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Signature", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Content-Sha256", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Date")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Date", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Credential")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Credential", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Security-Token")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Security-Token", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Algorithm")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Algorithm", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-SignedHeaders", valid_602069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602070: Call_DescribeJournalS3Export_602058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a journal export job, including the ledger name, export ID, when it was created, current status, and its start and end time export parameters.</p> <p>If the export job with the given <code>ExportId</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p>
  ## 
  let valid = call_602070.validator(path, query, header, formData, body)
  let scheme = call_602070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602070.url(scheme.get, call_602070.host, call_602070.base,
                         call_602070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602070, url, valid)

proc call*(call_602071: Call_DescribeJournalS3Export_602058; exportId: string;
          name: string): Recallable =
  ## describeJournalS3Export
  ## <p>Returns information about a journal export job, including the ledger name, export ID, when it was created, current status, and its start and end time export parameters.</p> <p>If the export job with the given <code>ExportId</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p>
  ##   exportId: string (required)
  ##           : The unique ID of the journal export job that you want to describe.
  ##   name: string (required)
  ##       : The name of the ledger.
  var path_602072 = newJObject()
  add(path_602072, "exportId", newJString(exportId))
  add(path_602072, "name", newJString(name))
  result = call_602071.call(path_602072, nil, nil, nil, nil)

var describeJournalS3Export* = Call_DescribeJournalS3Export_602058(
    name: "describeJournalS3Export", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com",
    route: "/ledgers/{name}/journal-s3-exports/{exportId}",
    validator: validate_DescribeJournalS3Export_602059, base: "/",
    url: url_DescribeJournalS3Export_602060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportJournalToS3_602092 = ref object of OpenApiRestCall_601389
proc url_ExportJournalToS3_602094(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ExportJournalToS3_602093(path: JsonNode; query: JsonNode;
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
  var valid_602095 = path.getOrDefault("name")
  valid_602095 = validateParameter(valid_602095, JString, required = true,
                                 default = nil)
  if valid_602095 != nil:
    section.add "name", valid_602095
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
  var valid_602096 = header.getOrDefault("X-Amz-Signature")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Signature", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-Content-Sha256", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-Date")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Date", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-Credential")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Credential", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Security-Token")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Security-Token", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-Algorithm")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Algorithm", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-SignedHeaders", valid_602102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602104: Call_ExportJournalToS3_602092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Exports journal contents within a date and time range from a ledger into a specified Amazon Simple Storage Service (Amazon S3) bucket. The data is written as files in Amazon Ion format.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>You can initiate up to two concurrent journal export requests for each ledger. Beyond this limit, journal export requests throw <code>LimitExceededException</code>.</p>
  ## 
  let valid = call_602104.validator(path, query, header, formData, body)
  let scheme = call_602104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602104.url(scheme.get, call_602104.host, call_602104.base,
                         call_602104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602104, url, valid)

proc call*(call_602105: Call_ExportJournalToS3_602092; name: string; body: JsonNode): Recallable =
  ## exportJournalToS3
  ## <p>Exports journal contents within a date and time range from a ledger into a specified Amazon Simple Storage Service (Amazon S3) bucket. The data is written as files in Amazon Ion format.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>You can initiate up to two concurrent journal export requests for each ledger. Beyond this limit, journal export requests throw <code>LimitExceededException</code>.</p>
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_602106 = newJObject()
  var body_602107 = newJObject()
  add(path_602106, "name", newJString(name))
  if body != nil:
    body_602107 = body
  result = call_602105.call(path_602106, nil, nil, nil, body_602107)

var exportJournalToS3* = Call_ExportJournalToS3_602092(name: "exportJournalToS3",
    meth: HttpMethod.HttpPost, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}/journal-s3-exports",
    validator: validate_ExportJournalToS3_602093, base: "/",
    url: url_ExportJournalToS3_602094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJournalS3ExportsForLedger_602073 = ref object of OpenApiRestCall_601389
proc url_ListJournalS3ExportsForLedger_602075(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListJournalS3ExportsForLedger_602074(path: JsonNode; query: JsonNode;
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
  var valid_602076 = path.getOrDefault("name")
  valid_602076 = validateParameter(valid_602076, JString, required = true,
                                 default = nil)
  if valid_602076 != nil:
    section.add "name", valid_602076
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
  var valid_602077 = query.getOrDefault("MaxResults")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "MaxResults", valid_602077
  var valid_602078 = query.getOrDefault("NextToken")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "NextToken", valid_602078
  var valid_602079 = query.getOrDefault("next_token")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "next_token", valid_602079
  var valid_602080 = query.getOrDefault("max_results")
  valid_602080 = validateParameter(valid_602080, JInt, required = false, default = nil)
  if valid_602080 != nil:
    section.add "max_results", valid_602080
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
  var valid_602081 = header.getOrDefault("X-Amz-Signature")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Signature", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Content-Sha256", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-Date")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Date", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-Credential")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Credential", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Security-Token")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Security-Token", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-Algorithm")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Algorithm", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-SignedHeaders", valid_602087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602088: Call_ListJournalS3ExportsForLedger_602073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an array of journal export job descriptions for a specified ledger.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3ExportsForLedger</code> multiple times.</p>
  ## 
  let valid = call_602088.validator(path, query, header, formData, body)
  let scheme = call_602088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602088.url(scheme.get, call_602088.host, call_602088.base,
                         call_602088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602088, url, valid)

proc call*(call_602089: Call_ListJournalS3ExportsForLedger_602073; name: string;
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
  var path_602090 = newJObject()
  var query_602091 = newJObject()
  add(query_602091, "MaxResults", newJString(MaxResults))
  add(query_602091, "NextToken", newJString(NextToken))
  add(path_602090, "name", newJString(name))
  add(query_602091, "next_token", newJString(nextToken))
  add(query_602091, "max_results", newJInt(maxResults))
  result = call_602089.call(path_602090, query_602091, nil, nil, nil)

var listJournalS3ExportsForLedger* = Call_ListJournalS3ExportsForLedger_602073(
    name: "listJournalS3ExportsForLedger", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com", route: "/ledgers/{name}/journal-s3-exports",
    validator: validate_ListJournalS3ExportsForLedger_602074, base: "/",
    url: url_ListJournalS3ExportsForLedger_602075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlock_602108 = ref object of OpenApiRestCall_601389
proc url_GetBlock_602110(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBlock_602109(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602111 = path.getOrDefault("name")
  valid_602111 = validateParameter(valid_602111, JString, required = true,
                                 default = nil)
  if valid_602111 != nil:
    section.add "name", valid_602111
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
  var valid_602112 = header.getOrDefault("X-Amz-Signature")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Signature", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Content-Sha256", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-Date")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-Date", valid_602114
  var valid_602115 = header.getOrDefault("X-Amz-Credential")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Credential", valid_602115
  var valid_602116 = header.getOrDefault("X-Amz-Security-Token")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-Security-Token", valid_602116
  var valid_602117 = header.getOrDefault("X-Amz-Algorithm")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-Algorithm", valid_602117
  var valid_602118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-SignedHeaders", valid_602118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602120: Call_GetBlock_602108; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a journal block object at a specified address in a ledger. Also returns a proof of the specified block for verification if <code>DigestTipAddress</code> is provided.</p> <p>If the specified ledger doesn't exist or is in <code>DELETING</code> status, then throws <code>ResourceNotFoundException</code>.</p> <p>If the specified ledger is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>If no block exists with the specified address, then throws <code>InvalidParameterException</code>.</p>
  ## 
  let valid = call_602120.validator(path, query, header, formData, body)
  let scheme = call_602120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602120.url(scheme.get, call_602120.host, call_602120.base,
                         call_602120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602120, url, valid)

proc call*(call_602121: Call_GetBlock_602108; name: string; body: JsonNode): Recallable =
  ## getBlock
  ## <p>Returns a journal block object at a specified address in a ledger. Also returns a proof of the specified block for verification if <code>DigestTipAddress</code> is provided.</p> <p>If the specified ledger doesn't exist or is in <code>DELETING</code> status, then throws <code>ResourceNotFoundException</code>.</p> <p>If the specified ledger is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>If no block exists with the specified address, then throws <code>InvalidParameterException</code>.</p>
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_602122 = newJObject()
  var body_602123 = newJObject()
  add(path_602122, "name", newJString(name))
  if body != nil:
    body_602123 = body
  result = call_602121.call(path_602122, nil, nil, nil, body_602123)

var getBlock* = Call_GetBlock_602108(name: "getBlock", meth: HttpMethod.HttpPost,
                                  host: "qldb.amazonaws.com",
                                  route: "/ledgers/{name}/block",
                                  validator: validate_GetBlock_602109, base: "/",
                                  url: url_GetBlock_602110,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDigest_602124 = ref object of OpenApiRestCall_601389
proc url_GetDigest_602126(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDigest_602125(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602127 = path.getOrDefault("name")
  valid_602127 = validateParameter(valid_602127, JString, required = true,
                                 default = nil)
  if valid_602127 != nil:
    section.add "name", valid_602127
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
  var valid_602128 = header.getOrDefault("X-Amz-Signature")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Signature", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-Content-Sha256", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-Date")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Date", valid_602130
  var valid_602131 = header.getOrDefault("X-Amz-Credential")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-Credential", valid_602131
  var valid_602132 = header.getOrDefault("X-Amz-Security-Token")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-Security-Token", valid_602132
  var valid_602133 = header.getOrDefault("X-Amz-Algorithm")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-Algorithm", valid_602133
  var valid_602134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-SignedHeaders", valid_602134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602135: Call_GetDigest_602124; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the digest of a ledger at the latest committed block in the journal. The response includes a 256-bit hash value and a block address.
  ## 
  let valid = call_602135.validator(path, query, header, formData, body)
  let scheme = call_602135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602135.url(scheme.get, call_602135.host, call_602135.base,
                         call_602135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602135, url, valid)

proc call*(call_602136: Call_GetDigest_602124; name: string): Recallable =
  ## getDigest
  ## Returns the digest of a ledger at the latest committed block in the journal. The response includes a 256-bit hash value and a block address.
  ##   name: string (required)
  ##       : The name of the ledger.
  var path_602137 = newJObject()
  add(path_602137, "name", newJString(name))
  result = call_602136.call(path_602137, nil, nil, nil, nil)

var getDigest* = Call_GetDigest_602124(name: "getDigest", meth: HttpMethod.HttpPost,
                                    host: "qldb.amazonaws.com",
                                    route: "/ledgers/{name}/digest",
                                    validator: validate_GetDigest_602125,
                                    base: "/", url: url_GetDigest_602126,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevision_602138 = ref object of OpenApiRestCall_601389
proc url_GetRevision_602140(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRevision_602139(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602141 = path.getOrDefault("name")
  valid_602141 = validateParameter(valid_602141, JString, required = true,
                                 default = nil)
  if valid_602141 != nil:
    section.add "name", valid_602141
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
  var valid_602142 = header.getOrDefault("X-Amz-Signature")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Signature", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Content-Sha256", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Date")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Date", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Credential")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Credential", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Security-Token")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Security-Token", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Algorithm")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Algorithm", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-SignedHeaders", valid_602148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602150: Call_GetRevision_602138; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a revision data object for a specified document ID and block address. Also returns a proof of the specified revision for verification if <code>DigestTipAddress</code> is provided.
  ## 
  let valid = call_602150.validator(path, query, header, formData, body)
  let scheme = call_602150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602150.url(scheme.get, call_602150.host, call_602150.base,
                         call_602150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602150, url, valid)

proc call*(call_602151: Call_GetRevision_602138; name: string; body: JsonNode): Recallable =
  ## getRevision
  ## Returns a revision data object for a specified document ID and block address. Also returns a proof of the specified revision for verification if <code>DigestTipAddress</code> is provided.
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_602152 = newJObject()
  var body_602153 = newJObject()
  add(path_602152, "name", newJString(name))
  if body != nil:
    body_602153 = body
  result = call_602151.call(path_602152, nil, nil, nil, body_602153)

var getRevision* = Call_GetRevision_602138(name: "getRevision",
                                        meth: HttpMethod.HttpPost,
                                        host: "qldb.amazonaws.com",
                                        route: "/ledgers/{name}/revision",
                                        validator: validate_GetRevision_602139,
                                        base: "/", url: url_GetRevision_602140,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJournalS3Exports_602154 = ref object of OpenApiRestCall_601389
proc url_ListJournalS3Exports_602156(protocol: Scheme; host: string; base: string;
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

proc validate_ListJournalS3Exports_602155(path: JsonNode; query: JsonNode;
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
  var valid_602157 = query.getOrDefault("MaxResults")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "MaxResults", valid_602157
  var valid_602158 = query.getOrDefault("NextToken")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "NextToken", valid_602158
  var valid_602159 = query.getOrDefault("next_token")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "next_token", valid_602159
  var valid_602160 = query.getOrDefault("max_results")
  valid_602160 = validateParameter(valid_602160, JInt, required = false, default = nil)
  if valid_602160 != nil:
    section.add "max_results", valid_602160
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
  var valid_602161 = header.getOrDefault("X-Amz-Signature")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Signature", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Content-Sha256", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Date")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Date", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Credential")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Credential", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Security-Token")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Security-Token", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Algorithm")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Algorithm", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-SignedHeaders", valid_602167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602168: Call_ListJournalS3Exports_602154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an array of journal export job descriptions for all ledgers that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3Exports</code> multiple times.</p>
  ## 
  let valid = call_602168.validator(path, query, header, formData, body)
  let scheme = call_602168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602168.url(scheme.get, call_602168.host, call_602168.base,
                         call_602168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602168, url, valid)

proc call*(call_602169: Call_ListJournalS3Exports_602154; MaxResults: string = "";
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
  var query_602170 = newJObject()
  add(query_602170, "MaxResults", newJString(MaxResults))
  add(query_602170, "NextToken", newJString(NextToken))
  add(query_602170, "next_token", newJString(nextToken))
  add(query_602170, "max_results", newJInt(maxResults))
  result = call_602169.call(nil, query_602170, nil, nil, nil)

var listJournalS3Exports* = Call_ListJournalS3Exports_602154(
    name: "listJournalS3Exports", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com", route: "/journal-s3-exports",
    validator: validate_ListJournalS3Exports_602155, base: "/",
    url: url_ListJournalS3Exports_602156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602185 = ref object of OpenApiRestCall_601389
proc url_TagResource_602187(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_602186(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602188 = path.getOrDefault("resourceArn")
  valid_602188 = validateParameter(valid_602188, JString, required = true,
                                 default = nil)
  if valid_602188 != nil:
    section.add "resourceArn", valid_602188
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
  var valid_602189 = header.getOrDefault("X-Amz-Signature")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Signature", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Content-Sha256", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Date")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Date", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Credential")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Credential", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Security-Token")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Security-Token", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Algorithm")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Algorithm", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-SignedHeaders", valid_602195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602197: Call_TagResource_602185; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to a specified Amazon QLDB resource.</p> <p>A resource can have up to 50 tags. If you try to create more than 50 tags for a resource, your request fails and returns an error.</p>
  ## 
  let valid = call_602197.validator(path, query, header, formData, body)
  let scheme = call_602197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602197.url(scheme.get, call_602197.host, call_602197.base,
                         call_602197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602197, url, valid)

proc call*(call_602198: Call_TagResource_602185; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds one or more tags to a specified Amazon QLDB resource.</p> <p>A resource can have up to 50 tags. If you try to create more than 50 tags for a resource, your request fails and returns an error.</p>
  ##   resourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) to which you want to add the tags. For example:</p> <p> <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> </p>
  ##   body: JObject (required)
  var path_602199 = newJObject()
  var body_602200 = newJObject()
  add(path_602199, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_602200 = body
  result = call_602198.call(path_602199, nil, nil, nil, body_602200)

var tagResource* = Call_TagResource_602185(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "qldb.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_602186,
                                        base: "/", url: url_TagResource_602187,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602171 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602173(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_602172(path: JsonNode; query: JsonNode;
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
  var valid_602174 = path.getOrDefault("resourceArn")
  valid_602174 = validateParameter(valid_602174, JString, required = true,
                                 default = nil)
  if valid_602174 != nil:
    section.add "resourceArn", valid_602174
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
  var valid_602175 = header.getOrDefault("X-Amz-Signature")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Signature", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Content-Sha256", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Date")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Date", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Credential")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Credential", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Security-Token")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Security-Token", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Algorithm")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Algorithm", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-SignedHeaders", valid_602181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602182: Call_ListTagsForResource_602171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tags for a specified Amazon QLDB resource.
  ## 
  let valid = call_602182.validator(path, query, header, formData, body)
  let scheme = call_602182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602182.url(scheme.get, call_602182.host, call_602182.base,
                         call_602182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602182, url, valid)

proc call*(call_602183: Call_ListTagsForResource_602171; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns all tags for a specified Amazon QLDB resource.
  ##   resourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) for which you want to list the tags. For example:</p> <p> <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> </p>
  var path_602184 = newJObject()
  add(path_602184, "resourceArn", newJString(resourceArn))
  result = call_602183.call(path_602184, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_602171(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_602172, base: "/",
    url: url_ListTagsForResource_602173, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602201 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602203(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_602202(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602204 = path.getOrDefault("resourceArn")
  valid_602204 = validateParameter(valid_602204, JString, required = true,
                                 default = nil)
  if valid_602204 != nil:
    section.add "resourceArn", valid_602204
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The list of tag keys that you want to remove.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_602205 = query.getOrDefault("tagKeys")
  valid_602205 = validateParameter(valid_602205, JArray, required = true, default = nil)
  if valid_602205 != nil:
    section.add "tagKeys", valid_602205
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
  var valid_602206 = header.getOrDefault("X-Amz-Signature")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-Signature", valid_602206
  var valid_602207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-Content-Sha256", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-Date")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-Date", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-Credential")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Credential", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Security-Token")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Security-Token", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Algorithm")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Algorithm", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-SignedHeaders", valid_602212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602213: Call_UntagResource_602201; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a specified Amazon QLDB resource. You can specify up to 50 tag keys to remove.
  ## 
  let valid = call_602213.validator(path, query, header, formData, body)
  let scheme = call_602213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602213.url(scheme.get, call_602213.host, call_602213.base,
                         call_602213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602213, url, valid)

proc call*(call_602214: Call_UntagResource_602201; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes one or more tags from a specified Amazon QLDB resource. You can specify up to 50 tag keys to remove.
  ##   resourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) from which you want to remove the tags. For example:</p> <p> <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> </p>
  ##   tagKeys: JArray (required)
  ##          : The list of tag keys that you want to remove.
  var path_602215 = newJObject()
  var query_602216 = newJObject()
  add(path_602215, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_602216.add "tagKeys", tagKeys
  result = call_602214.call(path_602215, query_602216, nil, nil, nil)

var untagResource* = Call_UntagResource_602201(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "qldb.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_602202,
    base: "/", url: url_UntagResource_602203, schemes: {Scheme.Https, Scheme.Http})
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
