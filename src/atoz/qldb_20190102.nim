
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateLedger_601027 = ref object of OpenApiRestCall_600426
proc url_CreateLedger_601029(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateLedger_601028(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601030 = header.getOrDefault("X-Amz-Date")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Date", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Security-Token")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Security-Token", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Content-Sha256", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-Algorithm")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-Algorithm", valid_601033
  var valid_601034 = header.getOrDefault("X-Amz-Signature")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "X-Amz-Signature", valid_601034
  var valid_601035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-SignedHeaders", valid_601035
  var valid_601036 = header.getOrDefault("X-Amz-Credential")
  valid_601036 = validateParameter(valid_601036, JString, required = false,
                                 default = nil)
  if valid_601036 != nil:
    section.add "X-Amz-Credential", valid_601036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601038: Call_CreateLedger_601027; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new ledger in your AWS account.
  ## 
  let valid = call_601038.validator(path, query, header, formData, body)
  let scheme = call_601038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601038.url(scheme.get, call_601038.host, call_601038.base,
                         call_601038.route, valid.getOrDefault("path"))
  result = hook(call_601038, url, valid)

proc call*(call_601039: Call_CreateLedger_601027; body: JsonNode): Recallable =
  ## createLedger
  ## Creates a new ledger in your AWS account.
  ##   body: JObject (required)
  var body_601040 = newJObject()
  if body != nil:
    body_601040 = body
  result = call_601039.call(nil, nil, nil, nil, body_601040)

var createLedger* = Call_CreateLedger_601027(name: "createLedger",
    meth: HttpMethod.HttpPost, host: "qldb.amazonaws.com", route: "/ledgers",
    validator: validate_CreateLedger_601028, base: "/", url: url_CreateLedger_601029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLedgers_600768 = ref object of OpenApiRestCall_600426
proc url_ListLedgers_600770(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListLedgers_600769(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600882 = query.getOrDefault("NextToken")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "NextToken", valid_600882
  var valid_600883 = query.getOrDefault("next_token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "next_token", valid_600883
  var valid_600884 = query.getOrDefault("max_results")
  valid_600884 = validateParameter(valid_600884, JInt, required = false, default = nil)
  if valid_600884 != nil:
    section.add "max_results", valid_600884
  var valid_600885 = query.getOrDefault("MaxResults")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "MaxResults", valid_600885
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
  var valid_600886 = header.getOrDefault("X-Amz-Date")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Date", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-Security-Token")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Security-Token", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Content-Sha256", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Algorithm")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Algorithm", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Signature")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Signature", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-SignedHeaders", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Credential")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Credential", valid_600892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600915: Call_ListLedgers_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an array of ledger summaries that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of 100 items and is paginated so that you can retrieve all the items by calling <code>ListLedgers</code> multiple times.</p>
  ## 
  let valid = call_600915.validator(path, query, header, formData, body)
  let scheme = call_600915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600915.url(scheme.get, call_600915.host, call_600915.base,
                         call_600915.route, valid.getOrDefault("path"))
  result = hook(call_600915, url, valid)

proc call*(call_600986: Call_ListLedgers_600768; NextToken: string = "";
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
  var query_600987 = newJObject()
  add(query_600987, "NextToken", newJString(NextToken))
  add(query_600987, "next_token", newJString(nextToken))
  add(query_600987, "max_results", newJInt(maxResults))
  add(query_600987, "MaxResults", newJString(MaxResults))
  result = call_600986.call(nil, query_600987, nil, nil, nil)

var listLedgers* = Call_ListLedgers_600768(name: "listLedgers",
                                        meth: HttpMethod.HttpGet,
                                        host: "qldb.amazonaws.com",
                                        route: "/ledgers",
                                        validator: validate_ListLedgers_600769,
                                        base: "/", url: url_ListLedgers_600770,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLedger_601041 = ref object of OpenApiRestCall_600426
proc url_DescribeLedger_601043(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeLedger_601042(path: JsonNode; query: JsonNode;
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
  var valid_601058 = path.getOrDefault("name")
  valid_601058 = validateParameter(valid_601058, JString, required = true,
                                 default = nil)
  if valid_601058 != nil:
    section.add "name", valid_601058
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
  var valid_601059 = header.getOrDefault("X-Amz-Date")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Date", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Security-Token")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Security-Token", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Content-Sha256", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Algorithm")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Algorithm", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Signature")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Signature", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-SignedHeaders", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Credential")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Credential", valid_601065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601066: Call_DescribeLedger_601041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a ledger, including its state and when it was created.
  ## 
  let valid = call_601066.validator(path, query, header, formData, body)
  let scheme = call_601066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601066.url(scheme.get, call_601066.host, call_601066.base,
                         call_601066.route, valid.getOrDefault("path"))
  result = hook(call_601066, url, valid)

proc call*(call_601067: Call_DescribeLedger_601041; name: string): Recallable =
  ## describeLedger
  ## Returns information about a ledger, including its state and when it was created.
  ##   name: string (required)
  ##       : The name of the ledger that you want to describe.
  var path_601068 = newJObject()
  add(path_601068, "name", newJString(name))
  result = call_601067.call(path_601068, nil, nil, nil, nil)

var describeLedger* = Call_DescribeLedger_601041(name: "describeLedger",
    meth: HttpMethod.HttpGet, host: "qldb.amazonaws.com", route: "/ledgers/{name}",
    validator: validate_DescribeLedger_601042, base: "/", url: url_DescribeLedger_601043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLedger_601083 = ref object of OpenApiRestCall_600426
proc url_UpdateLedger_601085(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateLedger_601084(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601086 = path.getOrDefault("name")
  valid_601086 = validateParameter(valid_601086, JString, required = true,
                                 default = nil)
  if valid_601086 != nil:
    section.add "name", valid_601086
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
  var valid_601087 = header.getOrDefault("X-Amz-Date")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Date", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Security-Token")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Security-Token", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Content-Sha256", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Algorithm")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Algorithm", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Signature")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Signature", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-SignedHeaders", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Credential")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Credential", valid_601093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601095: Call_UpdateLedger_601083; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates properties on a ledger.
  ## 
  let valid = call_601095.validator(path, query, header, formData, body)
  let scheme = call_601095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601095.url(scheme.get, call_601095.host, call_601095.base,
                         call_601095.route, valid.getOrDefault("path"))
  result = hook(call_601095, url, valid)

proc call*(call_601096: Call_UpdateLedger_601083; name: string; body: JsonNode): Recallable =
  ## updateLedger
  ## Updates properties on a ledger.
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_601097 = newJObject()
  var body_601098 = newJObject()
  add(path_601097, "name", newJString(name))
  if body != nil:
    body_601098 = body
  result = call_601096.call(path_601097, nil, nil, nil, body_601098)

var updateLedger* = Call_UpdateLedger_601083(name: "updateLedger",
    meth: HttpMethod.HttpPatch, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}", validator: validate_UpdateLedger_601084, base: "/",
    url: url_UpdateLedger_601085, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLedger_601069 = ref object of OpenApiRestCall_600426
proc url_DeleteLedger_601071(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteLedger_601070(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601072 = path.getOrDefault("name")
  valid_601072 = validateParameter(valid_601072, JString, required = true,
                                 default = nil)
  if valid_601072 != nil:
    section.add "name", valid_601072
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
  var valid_601073 = header.getOrDefault("X-Amz-Date")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Date", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Security-Token")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Security-Token", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Content-Sha256", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Algorithm")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Algorithm", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Signature")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Signature", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-SignedHeaders", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Credential")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Credential", valid_601079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601080: Call_DeleteLedger_601069; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a ledger and all of its contents. This action is irreversible.</p> <p>If deletion protection is enabled, you must first disable it before you can delete the ledger using the QLDB API or the AWS Command Line Interface (AWS CLI). You can disable it by calling the <code>UpdateLedger</code> operation to set the flag to <code>false</code>. The QLDB console disables deletion protection for you when you use it to delete a ledger.</p>
  ## 
  let valid = call_601080.validator(path, query, header, formData, body)
  let scheme = call_601080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601080.url(scheme.get, call_601080.host, call_601080.base,
                         call_601080.route, valid.getOrDefault("path"))
  result = hook(call_601080, url, valid)

proc call*(call_601081: Call_DeleteLedger_601069; name: string): Recallable =
  ## deleteLedger
  ## <p>Deletes a ledger and all of its contents. This action is irreversible.</p> <p>If deletion protection is enabled, you must first disable it before you can delete the ledger using the QLDB API or the AWS Command Line Interface (AWS CLI). You can disable it by calling the <code>UpdateLedger</code> operation to set the flag to <code>false</code>. The QLDB console disables deletion protection for you when you use it to delete a ledger.</p>
  ##   name: string (required)
  ##       : The name of the ledger that you want to delete.
  var path_601082 = newJObject()
  add(path_601082, "name", newJString(name))
  result = call_601081.call(path_601082, nil, nil, nil, nil)

var deleteLedger* = Call_DeleteLedger_601069(name: "deleteLedger",
    meth: HttpMethod.HttpDelete, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}", validator: validate_DeleteLedger_601070, base: "/",
    url: url_DeleteLedger_601071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJournalS3Export_601099 = ref object of OpenApiRestCall_600426
proc url_DescribeJournalS3Export_601101(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeJournalS3Export_601100(path: JsonNode; query: JsonNode;
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
  var valid_601102 = path.getOrDefault("name")
  valid_601102 = validateParameter(valid_601102, JString, required = true,
                                 default = nil)
  if valid_601102 != nil:
    section.add "name", valid_601102
  var valid_601103 = path.getOrDefault("exportId")
  valid_601103 = validateParameter(valid_601103, JString, required = true,
                                 default = nil)
  if valid_601103 != nil:
    section.add "exportId", valid_601103
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
  var valid_601104 = header.getOrDefault("X-Amz-Date")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Date", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Security-Token")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Security-Token", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Content-Sha256", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Algorithm")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Algorithm", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Signature")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Signature", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-SignedHeaders", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Credential")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Credential", valid_601110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601111: Call_DescribeJournalS3Export_601099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a journal export job, including the ledger name, export ID, when it was created, current status, and its start and end time export parameters.</p> <p>If the export job with the given <code>ExportId</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p>
  ## 
  let valid = call_601111.validator(path, query, header, formData, body)
  let scheme = call_601111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601111.url(scheme.get, call_601111.host, call_601111.base,
                         call_601111.route, valid.getOrDefault("path"))
  result = hook(call_601111, url, valid)

proc call*(call_601112: Call_DescribeJournalS3Export_601099; name: string;
          exportId: string): Recallable =
  ## describeJournalS3Export
  ## <p>Returns information about a journal export job, including the ledger name, export ID, when it was created, current status, and its start and end time export parameters.</p> <p>If the export job with the given <code>ExportId</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p>
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   exportId: string (required)
  ##           : The unique ID of the journal export job that you want to describe.
  var path_601113 = newJObject()
  add(path_601113, "name", newJString(name))
  add(path_601113, "exportId", newJString(exportId))
  result = call_601112.call(path_601113, nil, nil, nil, nil)

var describeJournalS3Export* = Call_DescribeJournalS3Export_601099(
    name: "describeJournalS3Export", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com",
    route: "/ledgers/{name}/journal-s3-exports/{exportId}",
    validator: validate_DescribeJournalS3Export_601100, base: "/",
    url: url_DescribeJournalS3Export_601101, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ExportJournalToS3_601133 = ref object of OpenApiRestCall_600426
proc url_ExportJournalToS3_601135(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/journal-s3-exports")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ExportJournalToS3_601134(path: JsonNode; query: JsonNode;
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
  var valid_601136 = path.getOrDefault("name")
  valid_601136 = validateParameter(valid_601136, JString, required = true,
                                 default = nil)
  if valid_601136 != nil:
    section.add "name", valid_601136
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
  var valid_601137 = header.getOrDefault("X-Amz-Date")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Date", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-Security-Token")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-Security-Token", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Content-Sha256", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Algorithm")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Algorithm", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Signature")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Signature", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-SignedHeaders", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Credential")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Credential", valid_601143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601145: Call_ExportJournalToS3_601133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Exports journal contents within a date and time range from a ledger into a specified Amazon Simple Storage Service (Amazon S3) bucket. The data is written as files in Amazon Ion format.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>You can initiate up to two concurrent journal export requests for each ledger. Beyond this limit, journal export requests throw <code>LimitExceededException</code>.</p>
  ## 
  let valid = call_601145.validator(path, query, header, formData, body)
  let scheme = call_601145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601145.url(scheme.get, call_601145.host, call_601145.base,
                         call_601145.route, valid.getOrDefault("path"))
  result = hook(call_601145, url, valid)

proc call*(call_601146: Call_ExportJournalToS3_601133; name: string; body: JsonNode): Recallable =
  ## exportJournalToS3
  ## <p>Exports journal contents within a date and time range from a ledger into a specified Amazon Simple Storage Service (Amazon S3) bucket. The data is written as files in Amazon Ion format.</p> <p>If the ledger with the given <code>Name</code> doesn't exist, then throws <code>ResourceNotFoundException</code>.</p> <p>If the ledger with the given <code>Name</code> is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>You can initiate up to two concurrent journal export requests for each ledger. Beyond this limit, journal export requests throw <code>LimitExceededException</code>.</p>
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_601147 = newJObject()
  var body_601148 = newJObject()
  add(path_601147, "name", newJString(name))
  if body != nil:
    body_601148 = body
  result = call_601146.call(path_601147, nil, nil, nil, body_601148)

var exportJournalToS3* = Call_ExportJournalToS3_601133(name: "exportJournalToS3",
    meth: HttpMethod.HttpPost, host: "qldb.amazonaws.com",
    route: "/ledgers/{name}/journal-s3-exports",
    validator: validate_ExportJournalToS3_601134, base: "/",
    url: url_ExportJournalToS3_601135, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJournalS3ExportsForLedger_601114 = ref object of OpenApiRestCall_600426
proc url_ListJournalS3ExportsForLedger_601116(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/journal-s3-exports")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListJournalS3ExportsForLedger_601115(path: JsonNode; query: JsonNode;
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
  var valid_601117 = path.getOrDefault("name")
  valid_601117 = validateParameter(valid_601117, JString, required = true,
                                 default = nil)
  if valid_601117 != nil:
    section.add "name", valid_601117
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
  var valid_601118 = query.getOrDefault("NextToken")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "NextToken", valid_601118
  var valid_601119 = query.getOrDefault("next_token")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "next_token", valid_601119
  var valid_601120 = query.getOrDefault("max_results")
  valid_601120 = validateParameter(valid_601120, JInt, required = false, default = nil)
  if valid_601120 != nil:
    section.add "max_results", valid_601120
  var valid_601121 = query.getOrDefault("MaxResults")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "MaxResults", valid_601121
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
  var valid_601122 = header.getOrDefault("X-Amz-Date")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Date", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-Security-Token")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Security-Token", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Content-Sha256", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Algorithm")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Algorithm", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Signature")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Signature", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-SignedHeaders", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Credential")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Credential", valid_601128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601129: Call_ListJournalS3ExportsForLedger_601114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an array of journal export job descriptions for a specified ledger.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3ExportsForLedger</code> multiple times.</p>
  ## 
  let valid = call_601129.validator(path, query, header, formData, body)
  let scheme = call_601129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601129.url(scheme.get, call_601129.host, call_601129.base,
                         call_601129.route, valid.getOrDefault("path"))
  result = hook(call_601129, url, valid)

proc call*(call_601130: Call_ListJournalS3ExportsForLedger_601114; name: string;
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
  var path_601131 = newJObject()
  var query_601132 = newJObject()
  add(path_601131, "name", newJString(name))
  add(query_601132, "NextToken", newJString(NextToken))
  add(query_601132, "next_token", newJString(nextToken))
  add(query_601132, "max_results", newJInt(maxResults))
  add(query_601132, "MaxResults", newJString(MaxResults))
  result = call_601130.call(path_601131, query_601132, nil, nil, nil)

var listJournalS3ExportsForLedger* = Call_ListJournalS3ExportsForLedger_601114(
    name: "listJournalS3ExportsForLedger", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com", route: "/ledgers/{name}/journal-s3-exports",
    validator: validate_ListJournalS3ExportsForLedger_601115, base: "/",
    url: url_ListJournalS3ExportsForLedger_601116,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlock_601149 = ref object of OpenApiRestCall_600426
proc url_GetBlock_601151(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/block")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetBlock_601150(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601152 = path.getOrDefault("name")
  valid_601152 = validateParameter(valid_601152, JString, required = true,
                                 default = nil)
  if valid_601152 != nil:
    section.add "name", valid_601152
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
  var valid_601153 = header.getOrDefault("X-Amz-Date")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Date", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Security-Token")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Security-Token", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Content-Sha256", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Algorithm")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Algorithm", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-Signature")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-Signature", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-SignedHeaders", valid_601158
  var valid_601159 = header.getOrDefault("X-Amz-Credential")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-Credential", valid_601159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601161: Call_GetBlock_601149; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a journal block object at a specified address in a ledger. Also returns a proof of the specified block for verification if <code>DigestTipAddress</code> is provided.</p> <p>If the specified ledger doesn't exist or is in <code>DELETING</code> status, then throws <code>ResourceNotFoundException</code>.</p> <p>If the specified ledger is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>If no block exists with the specified address, then throws <code>InvalidParameterException</code>.</p>
  ## 
  let valid = call_601161.validator(path, query, header, formData, body)
  let scheme = call_601161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601161.url(scheme.get, call_601161.host, call_601161.base,
                         call_601161.route, valid.getOrDefault("path"))
  result = hook(call_601161, url, valid)

proc call*(call_601162: Call_GetBlock_601149; name: string; body: JsonNode): Recallable =
  ## getBlock
  ## <p>Returns a journal block object at a specified address in a ledger. Also returns a proof of the specified block for verification if <code>DigestTipAddress</code> is provided.</p> <p>If the specified ledger doesn't exist or is in <code>DELETING</code> status, then throws <code>ResourceNotFoundException</code>.</p> <p>If the specified ledger is in <code>CREATING</code> status, then throws <code>ResourcePreconditionNotMetException</code>.</p> <p>If no block exists with the specified address, then throws <code>InvalidParameterException</code>.</p>
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_601163 = newJObject()
  var body_601164 = newJObject()
  add(path_601163, "name", newJString(name))
  if body != nil:
    body_601164 = body
  result = call_601162.call(path_601163, nil, nil, nil, body_601164)

var getBlock* = Call_GetBlock_601149(name: "getBlock", meth: HttpMethod.HttpPost,
                                  host: "qldb.amazonaws.com",
                                  route: "/ledgers/{name}/block",
                                  validator: validate_GetBlock_601150, base: "/",
                                  url: url_GetBlock_601151,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDigest_601165 = ref object of OpenApiRestCall_600426
proc url_GetDigest_601167(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/digest")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDigest_601166(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601168 = path.getOrDefault("name")
  valid_601168 = validateParameter(valid_601168, JString, required = true,
                                 default = nil)
  if valid_601168 != nil:
    section.add "name", valid_601168
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
  var valid_601169 = header.getOrDefault("X-Amz-Date")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Date", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Security-Token")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Security-Token", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Content-Sha256", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Algorithm")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Algorithm", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-Signature")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Signature", valid_601173
  var valid_601174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "X-Amz-SignedHeaders", valid_601174
  var valid_601175 = header.getOrDefault("X-Amz-Credential")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Credential", valid_601175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601176: Call_GetDigest_601165; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the digest of a ledger at the latest committed block in the journal. The response includes a 256-bit hash value and a block address.
  ## 
  let valid = call_601176.validator(path, query, header, formData, body)
  let scheme = call_601176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601176.url(scheme.get, call_601176.host, call_601176.base,
                         call_601176.route, valid.getOrDefault("path"))
  result = hook(call_601176, url, valid)

proc call*(call_601177: Call_GetDigest_601165; name: string): Recallable =
  ## getDigest
  ## Returns the digest of a ledger at the latest committed block in the journal. The response includes a 256-bit hash value and a block address.
  ##   name: string (required)
  ##       : The name of the ledger.
  var path_601178 = newJObject()
  add(path_601178, "name", newJString(name))
  result = call_601177.call(path_601178, nil, nil, nil, nil)

var getDigest* = Call_GetDigest_601165(name: "getDigest", meth: HttpMethod.HttpPost,
                                    host: "qldb.amazonaws.com",
                                    route: "/ledgers/{name}/digest",
                                    validator: validate_GetDigest_601166,
                                    base: "/", url: url_GetDigest_601167,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevision_601179 = ref object of OpenApiRestCall_600426
proc url_GetRevision_601181(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/ledgers/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/revision")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetRevision_601180(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601182 = path.getOrDefault("name")
  valid_601182 = validateParameter(valid_601182, JString, required = true,
                                 default = nil)
  if valid_601182 != nil:
    section.add "name", valid_601182
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
  var valid_601183 = header.getOrDefault("X-Amz-Date")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Date", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Security-Token")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Security-Token", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Content-Sha256", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Algorithm")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Algorithm", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-Signature")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-Signature", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-SignedHeaders", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Credential")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Credential", valid_601189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601191: Call_GetRevision_601179; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a revision data object for a specified document ID and block address. Also returns a proof of the specified revision for verification if <code>DigestTipAddress</code> is provided.
  ## 
  let valid = call_601191.validator(path, query, header, formData, body)
  let scheme = call_601191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601191.url(scheme.get, call_601191.host, call_601191.base,
                         call_601191.route, valid.getOrDefault("path"))
  result = hook(call_601191, url, valid)

proc call*(call_601192: Call_GetRevision_601179; name: string; body: JsonNode): Recallable =
  ## getRevision
  ## Returns a revision data object for a specified document ID and block address. Also returns a proof of the specified revision for verification if <code>DigestTipAddress</code> is provided.
  ##   name: string (required)
  ##       : The name of the ledger.
  ##   body: JObject (required)
  var path_601193 = newJObject()
  var body_601194 = newJObject()
  add(path_601193, "name", newJString(name))
  if body != nil:
    body_601194 = body
  result = call_601192.call(path_601193, nil, nil, nil, body_601194)

var getRevision* = Call_GetRevision_601179(name: "getRevision",
                                        meth: HttpMethod.HttpPost,
                                        host: "qldb.amazonaws.com",
                                        route: "/ledgers/{name}/revision",
                                        validator: validate_GetRevision_601180,
                                        base: "/", url: url_GetRevision_601181,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJournalS3Exports_601195 = ref object of OpenApiRestCall_600426
proc url_ListJournalS3Exports_601197(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListJournalS3Exports_601196(path: JsonNode; query: JsonNode;
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
  var valid_601198 = query.getOrDefault("NextToken")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "NextToken", valid_601198
  var valid_601199 = query.getOrDefault("next_token")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "next_token", valid_601199
  var valid_601200 = query.getOrDefault("max_results")
  valid_601200 = validateParameter(valid_601200, JInt, required = false, default = nil)
  if valid_601200 != nil:
    section.add "max_results", valid_601200
  var valid_601201 = query.getOrDefault("MaxResults")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "MaxResults", valid_601201
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
  var valid_601202 = header.getOrDefault("X-Amz-Date")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Date", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Security-Token")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Security-Token", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Content-Sha256", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-Algorithm")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Algorithm", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Signature")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Signature", valid_601206
  var valid_601207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-SignedHeaders", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Credential")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Credential", valid_601208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601209: Call_ListJournalS3Exports_601195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an array of journal export job descriptions for all ledgers that are associated with the current AWS account and Region.</p> <p>This action returns a maximum of <code>MaxResults</code> items, and is paginated so that you can retrieve all the items by calling <code>ListJournalS3Exports</code> multiple times.</p>
  ## 
  let valid = call_601209.validator(path, query, header, formData, body)
  let scheme = call_601209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601209.url(scheme.get, call_601209.host, call_601209.base,
                         call_601209.route, valid.getOrDefault("path"))
  result = hook(call_601209, url, valid)

proc call*(call_601210: Call_ListJournalS3Exports_601195; NextToken: string = "";
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
  var query_601211 = newJObject()
  add(query_601211, "NextToken", newJString(NextToken))
  add(query_601211, "next_token", newJString(nextToken))
  add(query_601211, "max_results", newJInt(maxResults))
  add(query_601211, "MaxResults", newJString(MaxResults))
  result = call_601210.call(nil, query_601211, nil, nil, nil)

var listJournalS3Exports* = Call_ListJournalS3Exports_601195(
    name: "listJournalS3Exports", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com", route: "/journal-s3-exports",
    validator: validate_ListJournalS3Exports_601196, base: "/",
    url: url_ListJournalS3Exports_601197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601226 = ref object of OpenApiRestCall_600426
proc url_TagResource_601228(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_TagResource_601227(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601229 = path.getOrDefault("resourceArn")
  valid_601229 = validateParameter(valid_601229, JString, required = true,
                                 default = nil)
  if valid_601229 != nil:
    section.add "resourceArn", valid_601229
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
  var valid_601230 = header.getOrDefault("X-Amz-Date")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Date", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Security-Token")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Security-Token", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Content-Sha256", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Algorithm")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Algorithm", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Signature")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Signature", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-SignedHeaders", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-Credential")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-Credential", valid_601236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601238: Call_TagResource_601226; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds one or more tags to a specified Amazon QLDB resource.</p> <p>A resource can have up to 50 tags. If you try to create more than 50 tags for a resource, your request fails and returns an error.</p>
  ## 
  let valid = call_601238.validator(path, query, header, formData, body)
  let scheme = call_601238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601238.url(scheme.get, call_601238.host, call_601238.base,
                         call_601238.route, valid.getOrDefault("path"))
  result = hook(call_601238, url, valid)

proc call*(call_601239: Call_TagResource_601226; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## <p>Adds one or more tags to a specified Amazon QLDB resource.</p> <p>A resource can have up to 50 tags. If you try to create more than 50 tags for a resource, your request fails and returns an error.</p>
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) to which you want to add the tags. For example:</p> <p> <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> </p>
  var path_601240 = newJObject()
  var body_601241 = newJObject()
  if body != nil:
    body_601241 = body
  add(path_601240, "resourceArn", newJString(resourceArn))
  result = call_601239.call(path_601240, nil, nil, nil, body_601241)

var tagResource* = Call_TagResource_601226(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "qldb.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_601227,
                                        base: "/", url: url_TagResource_601228,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601212 = ref object of OpenApiRestCall_600426
proc url_ListTagsForResource_601214(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListTagsForResource_601213(path: JsonNode; query: JsonNode;
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
  var valid_601215 = path.getOrDefault("resourceArn")
  valid_601215 = validateParameter(valid_601215, JString, required = true,
                                 default = nil)
  if valid_601215 != nil:
    section.add "resourceArn", valid_601215
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
  var valid_601216 = header.getOrDefault("X-Amz-Date")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Date", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Security-Token")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Security-Token", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Content-Sha256", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Algorithm")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Algorithm", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-Signature")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Signature", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-SignedHeaders", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-Credential")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Credential", valid_601222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601223: Call_ListTagsForResource_601212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tags for a specified Amazon QLDB resource.
  ## 
  let valid = call_601223.validator(path, query, header, formData, body)
  let scheme = call_601223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601223.url(scheme.get, call_601223.host, call_601223.base,
                         call_601223.route, valid.getOrDefault("path"))
  result = hook(call_601223, url, valid)

proc call*(call_601224: Call_ListTagsForResource_601212; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns all tags for a specified Amazon QLDB resource.
  ##   resourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) for which you want to list the tags. For example:</p> <p> <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> </p>
  var path_601225 = newJObject()
  add(path_601225, "resourceArn", newJString(resourceArn))
  result = call_601224.call(path_601225, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_601212(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "qldb.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_601213, base: "/",
    url: url_ListTagsForResource_601214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601242 = ref object of OpenApiRestCall_600426
proc url_UntagResource_601244(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UntagResource_601243(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601245 = path.getOrDefault("resourceArn")
  valid_601245 = validateParameter(valid_601245, JString, required = true,
                                 default = nil)
  if valid_601245 != nil:
    section.add "resourceArn", valid_601245
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The list of tag keys that you want to remove.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_601246 = query.getOrDefault("tagKeys")
  valid_601246 = validateParameter(valid_601246, JArray, required = true, default = nil)
  if valid_601246 != nil:
    section.add "tagKeys", valid_601246
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
  var valid_601247 = header.getOrDefault("X-Amz-Date")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Date", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Security-Token")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Security-Token", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Content-Sha256", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-Algorithm")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Algorithm", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Signature")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Signature", valid_601251
  var valid_601252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-SignedHeaders", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Credential")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Credential", valid_601253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601254: Call_UntagResource_601242; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes one or more tags from a specified Amazon QLDB resource. You can specify up to 50 tag keys to remove.
  ## 
  let valid = call_601254.validator(path, query, header, formData, body)
  let scheme = call_601254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601254.url(scheme.get, call_601254.host, call_601254.base,
                         call_601254.route, valid.getOrDefault("path"))
  result = hook(call_601254, url, valid)

proc call*(call_601255: Call_UntagResource_601242; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Removes one or more tags from a specified Amazon QLDB resource. You can specify up to 50 tag keys to remove.
  ##   tagKeys: JArray (required)
  ##          : The list of tag keys that you want to remove.
  ##   resourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) from which you want to remove the tags. For example:</p> <p> <code>arn:aws:qldb:us-east-1:123456789012:ledger/exampleLedger</code> </p>
  var path_601256 = newJObject()
  var query_601257 = newJObject()
  if tagKeys != nil:
    query_601257.add "tagKeys", tagKeys
  add(path_601256, "resourceArn", newJString(resourceArn))
  result = call_601255.call(path_601256, query_601257, nil, nil, nil)

var untagResource* = Call_UntagResource_601242(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "qldb.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_601243,
    base: "/", url: url_UntagResource_601244, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
