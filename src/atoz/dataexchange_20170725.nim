
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Data Exchange
## version: 2017-07-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS Data Exchange is a service that makes it easy for AWS customers to exchange data in the cloud. You can use the AWS Data Exchange APIs to create, update, manage, and access file-based data set in the AWS Cloud.</p><p>As a subscriber, you can view and access the data sets that you have an entitlement to through a subscription. You can use the APIS to download or copy your entitled data sets to Amazon S3 for use across a variety of AWS analytics and machine learning services.</p><p>As a provider, you can create and manage your data sets that you would like to publish to a product. Being able to package and provide your data sets into products requires a few steps to determine eligibility. For more information, visit the AWS Data Exchange User Guide.</p><p>A data set is a collection of data that can be changed or updated over time. Data sets can be updated using revisions, which represent a new version or incremental change to a data set.  A revision contains one or more assets. An asset in AWS Data Exchange is a piece of data that can be stored as an Amazon S3 object. The asset can be a structured data file, an image file, or some other data file. Jobs are asynchronous import or export operations used to create or copy assets.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/dataexchange/
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "dataexchange.ap-northeast-1.amazonaws.com", "ap-southeast-1": "dataexchange.ap-southeast-1.amazonaws.com",
                           "us-west-2": "dataexchange.us-west-2.amazonaws.com",
                           "eu-west-2": "dataexchange.eu-west-2.amazonaws.com", "ap-northeast-3": "dataexchange.ap-northeast-3.amazonaws.com", "eu-central-1": "dataexchange.eu-central-1.amazonaws.com",
                           "us-east-2": "dataexchange.us-east-2.amazonaws.com",
                           "us-east-1": "dataexchange.us-east-1.amazonaws.com", "cn-northwest-1": "dataexchange.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "dataexchange.ap-south-1.amazonaws.com", "eu-north-1": "dataexchange.eu-north-1.amazonaws.com", "ap-northeast-2": "dataexchange.ap-northeast-2.amazonaws.com",
                           "us-west-1": "dataexchange.us-west-1.amazonaws.com", "us-gov-east-1": "dataexchange.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "dataexchange.eu-west-3.amazonaws.com", "cn-north-1": "dataexchange.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "dataexchange.sa-east-1.amazonaws.com",
                           "eu-west-1": "dataexchange.eu-west-1.amazonaws.com", "us-gov-west-1": "dataexchange.us-gov-west-1.amazonaws.com", "ap-southeast-2": "dataexchange.ap-southeast-2.amazonaws.com", "ca-central-1": "dataexchange.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "dataexchange.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "dataexchange.ap-southeast-1.amazonaws.com",
      "us-west-2": "dataexchange.us-west-2.amazonaws.com",
      "eu-west-2": "dataexchange.eu-west-2.amazonaws.com",
      "ap-northeast-3": "dataexchange.ap-northeast-3.amazonaws.com",
      "eu-central-1": "dataexchange.eu-central-1.amazonaws.com",
      "us-east-2": "dataexchange.us-east-2.amazonaws.com",
      "us-east-1": "dataexchange.us-east-1.amazonaws.com",
      "cn-northwest-1": "dataexchange.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "dataexchange.ap-south-1.amazonaws.com",
      "eu-north-1": "dataexchange.eu-north-1.amazonaws.com",
      "ap-northeast-2": "dataexchange.ap-northeast-2.amazonaws.com",
      "us-west-1": "dataexchange.us-west-1.amazonaws.com",
      "us-gov-east-1": "dataexchange.us-gov-east-1.amazonaws.com",
      "eu-west-3": "dataexchange.eu-west-3.amazonaws.com",
      "cn-north-1": "dataexchange.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "dataexchange.sa-east-1.amazonaws.com",
      "eu-west-1": "dataexchange.eu-west-1.amazonaws.com",
      "us-gov-west-1": "dataexchange.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "dataexchange.ap-southeast-2.amazonaws.com",
      "ca-central-1": "dataexchange.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "dataexchange"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_GetJob_605927 = ref object of OpenApiRestCall_605589
proc url_GetJob_605929(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "JobId" in path, "`JobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/jobs/"),
               (kind: VariableSegment, value: "JobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJob_605928(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns information about a job.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   JobId: JString (required)
  ##        : The unique identifier for a job.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `JobId` field"
  var valid_606055 = path.getOrDefault("JobId")
  valid_606055 = validateParameter(valid_606055, JString, required = true,
                                 default = nil)
  if valid_606055 != nil:
    section.add "JobId", valid_606055
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
  var valid_606056 = header.getOrDefault("X-Amz-Signature")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Signature", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Content-Sha256", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Date")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Date", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Credential")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Credential", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Security-Token")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Security-Token", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Algorithm")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Algorithm", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-SignedHeaders", valid_606062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_GetJob_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job.
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_GetJob_605927; JobId: string): Recallable =
  ## getJob
  ## This operation returns information about a job.
  ##   JobId: string (required)
  ##        : The unique identifier for a job.
  var path_606157 = newJObject()
  add(path_606157, "JobId", newJString(JobId))
  result = call_606156.call(path_606157, nil, nil, nil, nil)

var getJob* = Call_GetJob_605927(name: "getJob", meth: HttpMethod.HttpGet,
                              host: "dataexchange.amazonaws.com",
                              route: "/v1/jobs/{JobId}",
                              validator: validate_GetJob_605928, base: "/",
                              url: url_GetJob_605929,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJob_606211 = ref object of OpenApiRestCall_605589
proc url_StartJob_606213(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "JobId" in path, "`JobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/jobs/"),
               (kind: VariableSegment, value: "JobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartJob_606212(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation starts a job.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   JobId: JString (required)
  ##        : The unique identifier for a job.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `JobId` field"
  var valid_606214 = path.getOrDefault("JobId")
  valid_606214 = validateParameter(valid_606214, JString, required = true,
                                 default = nil)
  if valid_606214 != nil:
    section.add "JobId", valid_606214
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
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606222: Call_StartJob_606211; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation starts a job.
  ## 
  let valid = call_606222.validator(path, query, header, formData, body)
  let scheme = call_606222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606222.url(scheme.get, call_606222.host, call_606222.base,
                         call_606222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606222, url, valid)

proc call*(call_606223: Call_StartJob_606211; JobId: string): Recallable =
  ## startJob
  ## This operation starts a job.
  ##   JobId: string (required)
  ##        : The unique identifier for a job.
  var path_606224 = newJObject()
  add(path_606224, "JobId", newJString(JobId))
  result = call_606223.call(path_606224, nil, nil, nil, nil)

var startJob* = Call_StartJob_606211(name: "startJob", meth: HttpMethod.HttpPatch,
                                  host: "dataexchange.amazonaws.com",
                                  route: "/v1/jobs/{JobId}",
                                  validator: validate_StartJob_606212, base: "/",
                                  url: url_StartJob_606213,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_606197 = ref object of OpenApiRestCall_605589
proc url_CancelJob_606199(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "JobId" in path, "`JobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/jobs/"),
               (kind: VariableSegment, value: "JobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelJob_606198(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation cancels a job. Jobs can be cancelled only when they are in the WAITING state.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   JobId: JString (required)
  ##        : The unique identifier for a job.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `JobId` field"
  var valid_606200 = path.getOrDefault("JobId")
  valid_606200 = validateParameter(valid_606200, JString, required = true,
                                 default = nil)
  if valid_606200 != nil:
    section.add "JobId", valid_606200
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
  var valid_606201 = header.getOrDefault("X-Amz-Signature")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Signature", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Content-Sha256", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Date")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Date", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Credential")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Credential", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Security-Token")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Security-Token", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Algorithm")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Algorithm", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-SignedHeaders", valid_606207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_CancelJob_606197; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a job. Jobs can be cancelled only when they are in the WAITING state.
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_CancelJob_606197; JobId: string): Recallable =
  ## cancelJob
  ## This operation cancels a job. Jobs can be cancelled only when they are in the WAITING state.
  ##   JobId: string (required)
  ##        : The unique identifier for a job.
  var path_606210 = newJObject()
  add(path_606210, "JobId", newJString(JobId))
  result = call_606209.call(path_606210, nil, nil, nil, nil)

var cancelJob* = Call_CancelJob_606197(name: "cancelJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "dataexchange.amazonaws.com",
                                    route: "/v1/jobs/{JobId}",
                                    validator: validate_CancelJob_606198,
                                    base: "/", url: url_CancelJob_606199,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSet_606243 = ref object of OpenApiRestCall_605589
proc url_CreateDataSet_606245(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDataSet_606244(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation creates a data set.
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
  var valid_606246 = header.getOrDefault("X-Amz-Signature")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Signature", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Content-Sha256", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Date")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Date", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Credential")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Credential", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Security-Token")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Security-Token", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-Algorithm")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-Algorithm", valid_606251
  var valid_606252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-SignedHeaders", valid_606252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606254: Call_CreateDataSet_606243; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation creates a data set.
  ## 
  let valid = call_606254.validator(path, query, header, formData, body)
  let scheme = call_606254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606254.url(scheme.get, call_606254.host, call_606254.base,
                         call_606254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606254, url, valid)

proc call*(call_606255: Call_CreateDataSet_606243; body: JsonNode): Recallable =
  ## createDataSet
  ## This operation creates a data set.
  ##   body: JObject (required)
  var body_606256 = newJObject()
  if body != nil:
    body_606256 = body
  result = call_606255.call(nil, nil, nil, nil, body_606256)

var createDataSet* = Call_CreateDataSet_606243(name: "createDataSet",
    meth: HttpMethod.HttpPost, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets", validator: validate_CreateDataSet_606244, base: "/",
    url: url_CreateDataSet_606245, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSets_606225 = ref object of OpenApiRestCall_605589
proc url_ListDataSets_606227(protocol: Scheme; host: string; base: string;
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

proc validate_ListDataSets_606226(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation lists your data sets. When listing by origin OWNED, results are sorted by CreatedAt in descending order. When listing by origin ENTITLED, there is no order and the maxResults parameter is ignored.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   origin: JString
  ##         : A property that defines the data set as OWNED by the account (for providers) or ENTITLED to the account (for subscribers).
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results returned by a single call.
  section = newJObject()
  var valid_606228 = query.getOrDefault("nextToken")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "nextToken", valid_606228
  var valid_606229 = query.getOrDefault("MaxResults")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "MaxResults", valid_606229
  var valid_606230 = query.getOrDefault("origin")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "origin", valid_606230
  var valid_606231 = query.getOrDefault("NextToken")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "NextToken", valid_606231
  var valid_606232 = query.getOrDefault("maxResults")
  valid_606232 = validateParameter(valid_606232, JInt, required = false, default = nil)
  if valid_606232 != nil:
    section.add "maxResults", valid_606232
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
  var valid_606233 = header.getOrDefault("X-Amz-Signature")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Signature", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Content-Sha256", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Date")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Date", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-Credential")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Credential", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Security-Token")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Security-Token", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Algorithm")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Algorithm", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-SignedHeaders", valid_606239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606240: Call_ListDataSets_606225; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists your data sets. When listing by origin OWNED, results are sorted by CreatedAt in descending order. When listing by origin ENTITLED, there is no order and the maxResults parameter is ignored.
  ## 
  let valid = call_606240.validator(path, query, header, formData, body)
  let scheme = call_606240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606240.url(scheme.get, call_606240.host, call_606240.base,
                         call_606240.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606240, url, valid)

proc call*(call_606241: Call_ListDataSets_606225; nextToken: string = "";
          MaxResults: string = ""; origin: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listDataSets
  ## This operation lists your data sets. When listing by origin OWNED, results are sorted by CreatedAt in descending order. When listing by origin ENTITLED, there is no order and the maxResults parameter is ignored.
  ##   nextToken: string
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   origin: string
  ##         : A property that defines the data set as OWNED by the account (for providers) or ENTITLED to the account (for subscribers).
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results returned by a single call.
  var query_606242 = newJObject()
  add(query_606242, "nextToken", newJString(nextToken))
  add(query_606242, "MaxResults", newJString(MaxResults))
  add(query_606242, "origin", newJString(origin))
  add(query_606242, "NextToken", newJString(NextToken))
  add(query_606242, "maxResults", newJInt(maxResults))
  result = call_606241.call(nil, query_606242, nil, nil, nil)

var listDataSets* = Call_ListDataSets_606225(name: "listDataSets",
    meth: HttpMethod.HttpGet, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets", validator: validate_ListDataSets_606226, base: "/",
    url: url_ListDataSets_606227, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_606276 = ref object of OpenApiRestCall_605589
proc url_CreateJob_606278(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateJob_606277(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation creates a job.
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
  var valid_606279 = header.getOrDefault("X-Amz-Signature")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Signature", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Content-Sha256", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-Date")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Date", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-Credential")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-Credential", valid_606282
  var valid_606283 = header.getOrDefault("X-Amz-Security-Token")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Security-Token", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-Algorithm")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Algorithm", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-SignedHeaders", valid_606285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606287: Call_CreateJob_606276; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation creates a job.
  ## 
  let valid = call_606287.validator(path, query, header, formData, body)
  let scheme = call_606287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606287.url(scheme.get, call_606287.host, call_606287.base,
                         call_606287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606287, url, valid)

proc call*(call_606288: Call_CreateJob_606276; body: JsonNode): Recallable =
  ## createJob
  ## This operation creates a job.
  ##   body: JObject (required)
  var body_606289 = newJObject()
  if body != nil:
    body_606289 = body
  result = call_606288.call(nil, nil, nil, nil, body_606289)

var createJob* = Call_CreateJob_606276(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "dataexchange.amazonaws.com",
                                    route: "/v1/jobs",
                                    validator: validate_CreateJob_606277,
                                    base: "/", url: url_CreateJob_606278,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_606257 = ref object of OpenApiRestCall_605589
proc url_ListJobs_606259(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListJobs_606258(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation lists your jobs sorted by CreatedAt in descending order.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   dataSetId: JString
  ##            : The unique identifier for a data set.
  ##   nextToken: JString
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   revisionId: JString
  ##             : The unique identifier for a revision.
  ##   maxResults: JInt
  ##             : The maximum number of results returned by a single call.
  section = newJObject()
  var valid_606260 = query.getOrDefault("dataSetId")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "dataSetId", valid_606260
  var valid_606261 = query.getOrDefault("nextToken")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "nextToken", valid_606261
  var valid_606262 = query.getOrDefault("MaxResults")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "MaxResults", valid_606262
  var valid_606263 = query.getOrDefault("NextToken")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "NextToken", valid_606263
  var valid_606264 = query.getOrDefault("revisionId")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "revisionId", valid_606264
  var valid_606265 = query.getOrDefault("maxResults")
  valid_606265 = validateParameter(valid_606265, JInt, required = false, default = nil)
  if valid_606265 != nil:
    section.add "maxResults", valid_606265
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
  var valid_606266 = header.getOrDefault("X-Amz-Signature")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Signature", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-Content-Sha256", valid_606267
  var valid_606268 = header.getOrDefault("X-Amz-Date")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Date", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-Credential")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Credential", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Security-Token")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Security-Token", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Algorithm")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Algorithm", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-SignedHeaders", valid_606272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606273: Call_ListJobs_606257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists your jobs sorted by CreatedAt in descending order.
  ## 
  let valid = call_606273.validator(path, query, header, formData, body)
  let scheme = call_606273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606273.url(scheme.get, call_606273.host, call_606273.base,
                         call_606273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606273, url, valid)

proc call*(call_606274: Call_ListJobs_606257; dataSetId: string = "";
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          revisionId: string = ""; maxResults: int = 0): Recallable =
  ## listJobs
  ## This operation lists your jobs sorted by CreatedAt in descending order.
  ##   dataSetId: string
  ##            : The unique identifier for a data set.
  ##   nextToken: string
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   revisionId: string
  ##             : The unique identifier for a revision.
  ##   maxResults: int
  ##             : The maximum number of results returned by a single call.
  var query_606275 = newJObject()
  add(query_606275, "dataSetId", newJString(dataSetId))
  add(query_606275, "nextToken", newJString(nextToken))
  add(query_606275, "MaxResults", newJString(MaxResults))
  add(query_606275, "NextToken", newJString(NextToken))
  add(query_606275, "revisionId", newJString(revisionId))
  add(query_606275, "maxResults", newJInt(maxResults))
  result = call_606274.call(nil, query_606275, nil, nil, nil)

var listJobs* = Call_ListJobs_606257(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "dataexchange.amazonaws.com",
                                  route: "/v1/jobs", validator: validate_ListJobs_606258,
                                  base: "/", url: url_ListJobs_606259,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRevision_606309 = ref object of OpenApiRestCall_605589
proc url_CreateRevision_606311(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRevision_606310(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## This operation creates a revision for a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_606312 = path.getOrDefault("DataSetId")
  valid_606312 = validateParameter(valid_606312, JString, required = true,
                                 default = nil)
  if valid_606312 != nil:
    section.add "DataSetId", valid_606312
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
  var valid_606313 = header.getOrDefault("X-Amz-Signature")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Signature", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Content-Sha256", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-Date")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-Date", valid_606315
  var valid_606316 = header.getOrDefault("X-Amz-Credential")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Credential", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-Security-Token")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-Security-Token", valid_606317
  var valid_606318 = header.getOrDefault("X-Amz-Algorithm")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-Algorithm", valid_606318
  var valid_606319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-SignedHeaders", valid_606319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606321: Call_CreateRevision_606309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation creates a revision for a data set.
  ## 
  let valid = call_606321.validator(path, query, header, formData, body)
  let scheme = call_606321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606321.url(scheme.get, call_606321.host, call_606321.base,
                         call_606321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606321, url, valid)

proc call*(call_606322: Call_CreateRevision_606309; DataSetId: string; body: JsonNode): Recallable =
  ## createRevision
  ## This operation creates a revision for a data set.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   body: JObject (required)
  var path_606323 = newJObject()
  var body_606324 = newJObject()
  add(path_606323, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_606324 = body
  result = call_606322.call(path_606323, nil, nil, nil, body_606324)

var createRevision* = Call_CreateRevision_606309(name: "createRevision",
    meth: HttpMethod.HttpPost, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions",
    validator: validate_CreateRevision_606310, base: "/", url: url_CreateRevision_606311,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSetRevisions_606290 = ref object of OpenApiRestCall_605589
proc url_ListDataSetRevisions_606292(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDataSetRevisions_606291(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation lists a data set's revisions sorted by CreatedAt in descending order.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_606293 = path.getOrDefault("DataSetId")
  valid_606293 = validateParameter(valid_606293, JString, required = true,
                                 default = nil)
  if valid_606293 != nil:
    section.add "DataSetId", valid_606293
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results returned by a single call.
  section = newJObject()
  var valid_606294 = query.getOrDefault("nextToken")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "nextToken", valid_606294
  var valid_606295 = query.getOrDefault("MaxResults")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "MaxResults", valid_606295
  var valid_606296 = query.getOrDefault("NextToken")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "NextToken", valid_606296
  var valid_606297 = query.getOrDefault("maxResults")
  valid_606297 = validateParameter(valid_606297, JInt, required = false, default = nil)
  if valid_606297 != nil:
    section.add "maxResults", valid_606297
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
  var valid_606298 = header.getOrDefault("X-Amz-Signature")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Signature", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Content-Sha256", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Date")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Date", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Credential")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Credential", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Security-Token")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Security-Token", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Algorithm")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Algorithm", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-SignedHeaders", valid_606304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606305: Call_ListDataSetRevisions_606290; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists a data set's revisions sorted by CreatedAt in descending order.
  ## 
  let valid = call_606305.validator(path, query, header, formData, body)
  let scheme = call_606305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606305.url(scheme.get, call_606305.host, call_606305.base,
                         call_606305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606305, url, valid)

proc call*(call_606306: Call_ListDataSetRevisions_606290; DataSetId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listDataSetRevisions
  ## This operation lists a data set's revisions sorted by CreatedAt in descending order.
  ##   nextToken: string
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   maxResults: int
  ##             : The maximum number of results returned by a single call.
  var path_606307 = newJObject()
  var query_606308 = newJObject()
  add(query_606308, "nextToken", newJString(nextToken))
  add(query_606308, "MaxResults", newJString(MaxResults))
  add(query_606308, "NextToken", newJString(NextToken))
  add(path_606307, "DataSetId", newJString(DataSetId))
  add(query_606308, "maxResults", newJInt(maxResults))
  result = call_606306.call(path_606307, query_606308, nil, nil, nil)

var listDataSetRevisions* = Call_ListDataSetRevisions_606290(
    name: "listDataSetRevisions", meth: HttpMethod.HttpGet,
    host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions",
    validator: validate_ListDataSetRevisions_606291, base: "/",
    url: url_ListDataSetRevisions_606292, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAsset_606325 = ref object of OpenApiRestCall_605589
proc url_GetAsset_606327(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  assert "AssetId" in path, "`AssetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId"),
               (kind: ConstantSegment, value: "/assets/"),
               (kind: VariableSegment, value: "AssetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAsset_606326(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns information about an asset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  ##   AssetId: JString (required)
  ##          : The unique identifier for an asset.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_606328 = path.getOrDefault("RevisionId")
  valid_606328 = validateParameter(valid_606328, JString, required = true,
                                 default = nil)
  if valid_606328 != nil:
    section.add "RevisionId", valid_606328
  var valid_606329 = path.getOrDefault("DataSetId")
  valid_606329 = validateParameter(valid_606329, JString, required = true,
                                 default = nil)
  if valid_606329 != nil:
    section.add "DataSetId", valid_606329
  var valid_606330 = path.getOrDefault("AssetId")
  valid_606330 = validateParameter(valid_606330, JString, required = true,
                                 default = nil)
  if valid_606330 != nil:
    section.add "AssetId", valid_606330
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
  var valid_606331 = header.getOrDefault("X-Amz-Signature")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "X-Amz-Signature", valid_606331
  var valid_606332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-Content-Sha256", valid_606332
  var valid_606333 = header.getOrDefault("X-Amz-Date")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-Date", valid_606333
  var valid_606334 = header.getOrDefault("X-Amz-Credential")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "X-Amz-Credential", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Security-Token")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Security-Token", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Algorithm")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Algorithm", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-SignedHeaders", valid_606337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606338: Call_GetAsset_606325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about an asset.
  ## 
  let valid = call_606338.validator(path, query, header, formData, body)
  let scheme = call_606338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606338.url(scheme.get, call_606338.host, call_606338.base,
                         call_606338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606338, url, valid)

proc call*(call_606339: Call_GetAsset_606325; RevisionId: string; DataSetId: string;
          AssetId: string): Recallable =
  ## getAsset
  ## This operation returns information about an asset.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   AssetId: string (required)
  ##          : The unique identifier for an asset.
  var path_606340 = newJObject()
  add(path_606340, "RevisionId", newJString(RevisionId))
  add(path_606340, "DataSetId", newJString(DataSetId))
  add(path_606340, "AssetId", newJString(AssetId))
  result = call_606339.call(path_606340, nil, nil, nil, nil)

var getAsset* = Call_GetAsset_606325(name: "getAsset", meth: HttpMethod.HttpGet,
                                  host: "dataexchange.amazonaws.com", route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets/{AssetId}",
                                  validator: validate_GetAsset_606326, base: "/",
                                  url: url_GetAsset_606327,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAsset_606357 = ref object of OpenApiRestCall_605589
proc url_UpdateAsset_606359(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  assert "AssetId" in path, "`AssetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId"),
               (kind: ConstantSegment, value: "/assets/"),
               (kind: VariableSegment, value: "AssetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAsset_606358(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation updates an asset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  ##   AssetId: JString (required)
  ##          : The unique identifier for an asset.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_606360 = path.getOrDefault("RevisionId")
  valid_606360 = validateParameter(valid_606360, JString, required = true,
                                 default = nil)
  if valid_606360 != nil:
    section.add "RevisionId", valid_606360
  var valid_606361 = path.getOrDefault("DataSetId")
  valid_606361 = validateParameter(valid_606361, JString, required = true,
                                 default = nil)
  if valid_606361 != nil:
    section.add "DataSetId", valid_606361
  var valid_606362 = path.getOrDefault("AssetId")
  valid_606362 = validateParameter(valid_606362, JString, required = true,
                                 default = nil)
  if valid_606362 != nil:
    section.add "AssetId", valid_606362
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
  var valid_606363 = header.getOrDefault("X-Amz-Signature")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Signature", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-Content-Sha256", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Date")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Date", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Credential")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Credential", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Security-Token")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Security-Token", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Algorithm")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Algorithm", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-SignedHeaders", valid_606369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606371: Call_UpdateAsset_606357; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation updates an asset.
  ## 
  let valid = call_606371.validator(path, query, header, formData, body)
  let scheme = call_606371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606371.url(scheme.get, call_606371.host, call_606371.base,
                         call_606371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606371, url, valid)

proc call*(call_606372: Call_UpdateAsset_606357; RevisionId: string;
          DataSetId: string; body: JsonNode; AssetId: string): Recallable =
  ## updateAsset
  ## This operation updates an asset.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   body: JObject (required)
  ##   AssetId: string (required)
  ##          : The unique identifier for an asset.
  var path_606373 = newJObject()
  var body_606374 = newJObject()
  add(path_606373, "RevisionId", newJString(RevisionId))
  add(path_606373, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_606374 = body
  add(path_606373, "AssetId", newJString(AssetId))
  result = call_606372.call(path_606373, nil, nil, nil, body_606374)

var updateAsset* = Call_UpdateAsset_606357(name: "updateAsset",
                                        meth: HttpMethod.HttpPatch,
                                        host: "dataexchange.amazonaws.com", route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets/{AssetId}",
                                        validator: validate_UpdateAsset_606358,
                                        base: "/", url: url_UpdateAsset_606359,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAsset_606341 = ref object of OpenApiRestCall_605589
proc url_DeleteAsset_606343(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  assert "AssetId" in path, "`AssetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId"),
               (kind: ConstantSegment, value: "/assets/"),
               (kind: VariableSegment, value: "AssetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAsset_606342(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation deletes an asset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  ##   AssetId: JString (required)
  ##          : The unique identifier for an asset.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_606344 = path.getOrDefault("RevisionId")
  valid_606344 = validateParameter(valid_606344, JString, required = true,
                                 default = nil)
  if valid_606344 != nil:
    section.add "RevisionId", valid_606344
  var valid_606345 = path.getOrDefault("DataSetId")
  valid_606345 = validateParameter(valid_606345, JString, required = true,
                                 default = nil)
  if valid_606345 != nil:
    section.add "DataSetId", valid_606345
  var valid_606346 = path.getOrDefault("AssetId")
  valid_606346 = validateParameter(valid_606346, JString, required = true,
                                 default = nil)
  if valid_606346 != nil:
    section.add "AssetId", valid_606346
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
  var valid_606347 = header.getOrDefault("X-Amz-Signature")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Signature", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-Content-Sha256", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-Date")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-Date", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Credential")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Credential", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Security-Token")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Security-Token", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Algorithm")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Algorithm", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-SignedHeaders", valid_606353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606354: Call_DeleteAsset_606341; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation deletes an asset.
  ## 
  let valid = call_606354.validator(path, query, header, formData, body)
  let scheme = call_606354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606354.url(scheme.get, call_606354.host, call_606354.base,
                         call_606354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606354, url, valid)

proc call*(call_606355: Call_DeleteAsset_606341; RevisionId: string;
          DataSetId: string; AssetId: string): Recallable =
  ## deleteAsset
  ## This operation deletes an asset.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   AssetId: string (required)
  ##          : The unique identifier for an asset.
  var path_606356 = newJObject()
  add(path_606356, "RevisionId", newJString(RevisionId))
  add(path_606356, "DataSetId", newJString(DataSetId))
  add(path_606356, "AssetId", newJString(AssetId))
  result = call_606355.call(path_606356, nil, nil, nil, nil)

var deleteAsset* = Call_DeleteAsset_606341(name: "deleteAsset",
                                        meth: HttpMethod.HttpDelete,
                                        host: "dataexchange.amazonaws.com", route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets/{AssetId}",
                                        validator: validate_DeleteAsset_606342,
                                        base: "/", url: url_DeleteAsset_606343,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataSet_606375 = ref object of OpenApiRestCall_605589
proc url_GetDataSet_606377(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDataSet_606376(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns information about a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_606378 = path.getOrDefault("DataSetId")
  valid_606378 = validateParameter(valid_606378, JString, required = true,
                                 default = nil)
  if valid_606378 != nil:
    section.add "DataSetId", valid_606378
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
  var valid_606379 = header.getOrDefault("X-Amz-Signature")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Signature", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Content-Sha256", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Date")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Date", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Credential")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Credential", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Security-Token")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Security-Token", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Algorithm")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Algorithm", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-SignedHeaders", valid_606385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606386: Call_GetDataSet_606375; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a data set.
  ## 
  let valid = call_606386.validator(path, query, header, formData, body)
  let scheme = call_606386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606386.url(scheme.get, call_606386.host, call_606386.base,
                         call_606386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606386, url, valid)

proc call*(call_606387: Call_GetDataSet_606375; DataSetId: string): Recallable =
  ## getDataSet
  ## This operation returns information about a data set.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_606388 = newJObject()
  add(path_606388, "DataSetId", newJString(DataSetId))
  result = call_606387.call(path_606388, nil, nil, nil, nil)

var getDataSet* = Call_GetDataSet_606375(name: "getDataSet",
                                      meth: HttpMethod.HttpGet,
                                      host: "dataexchange.amazonaws.com",
                                      route: "/v1/data-sets/{DataSetId}",
                                      validator: validate_GetDataSet_606376,
                                      base: "/", url: url_GetDataSet_606377,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSet_606403 = ref object of OpenApiRestCall_605589
proc url_UpdateDataSet_606405(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSet_606404(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation updates a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_606406 = path.getOrDefault("DataSetId")
  valid_606406 = validateParameter(valid_606406, JString, required = true,
                                 default = nil)
  if valid_606406 != nil:
    section.add "DataSetId", valid_606406
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
  var valid_606407 = header.getOrDefault("X-Amz-Signature")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Signature", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Content-Sha256", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-Date")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-Date", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Credential")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Credential", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Security-Token")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Security-Token", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Algorithm")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Algorithm", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-SignedHeaders", valid_606413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606415: Call_UpdateDataSet_606403; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation updates a data set.
  ## 
  let valid = call_606415.validator(path, query, header, formData, body)
  let scheme = call_606415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606415.url(scheme.get, call_606415.host, call_606415.base,
                         call_606415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606415, url, valid)

proc call*(call_606416: Call_UpdateDataSet_606403; DataSetId: string; body: JsonNode): Recallable =
  ## updateDataSet
  ## This operation updates a data set.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   body: JObject (required)
  var path_606417 = newJObject()
  var body_606418 = newJObject()
  add(path_606417, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_606418 = body
  result = call_606416.call(path_606417, nil, nil, nil, body_606418)

var updateDataSet* = Call_UpdateDataSet_606403(name: "updateDataSet",
    meth: HttpMethod.HttpPatch, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}", validator: validate_UpdateDataSet_606404,
    base: "/", url: url_UpdateDataSet_606405, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSet_606389 = ref object of OpenApiRestCall_605589
proc url_DeleteDataSet_606391(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataSet_606390(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation deletes a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_606392 = path.getOrDefault("DataSetId")
  valid_606392 = validateParameter(valid_606392, JString, required = true,
                                 default = nil)
  if valid_606392 != nil:
    section.add "DataSetId", valid_606392
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
  var valid_606393 = header.getOrDefault("X-Amz-Signature")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Signature", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Content-Sha256", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Date")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Date", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Credential")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Credential", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Security-Token")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Security-Token", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Algorithm")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Algorithm", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-SignedHeaders", valid_606399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606400: Call_DeleteDataSet_606389; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation deletes a data set.
  ## 
  let valid = call_606400.validator(path, query, header, formData, body)
  let scheme = call_606400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606400.url(scheme.get, call_606400.host, call_606400.base,
                         call_606400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606400, url, valid)

proc call*(call_606401: Call_DeleteDataSet_606389; DataSetId: string): Recallable =
  ## deleteDataSet
  ## This operation deletes a data set.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_606402 = newJObject()
  add(path_606402, "DataSetId", newJString(DataSetId))
  result = call_606401.call(path_606402, nil, nil, nil, nil)

var deleteDataSet* = Call_DeleteDataSet_606389(name: "deleteDataSet",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}", validator: validate_DeleteDataSet_606390,
    base: "/", url: url_DeleteDataSet_606391, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevision_606419 = ref object of OpenApiRestCall_605589
proc url_GetRevision_606421(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRevision_606420(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns information about a revision.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_606422 = path.getOrDefault("RevisionId")
  valid_606422 = validateParameter(valid_606422, JString, required = true,
                                 default = nil)
  if valid_606422 != nil:
    section.add "RevisionId", valid_606422
  var valid_606423 = path.getOrDefault("DataSetId")
  valid_606423 = validateParameter(valid_606423, JString, required = true,
                                 default = nil)
  if valid_606423 != nil:
    section.add "DataSetId", valid_606423
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
  var valid_606424 = header.getOrDefault("X-Amz-Signature")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-Signature", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Content-Sha256", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Date")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Date", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Credential")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Credential", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Security-Token")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Security-Token", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Algorithm")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Algorithm", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-SignedHeaders", valid_606430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606431: Call_GetRevision_606419; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a revision.
  ## 
  let valid = call_606431.validator(path, query, header, formData, body)
  let scheme = call_606431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606431.url(scheme.get, call_606431.host, call_606431.base,
                         call_606431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606431, url, valid)

proc call*(call_606432: Call_GetRevision_606419; RevisionId: string;
          DataSetId: string): Recallable =
  ## getRevision
  ## This operation returns information about a revision.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_606433 = newJObject()
  add(path_606433, "RevisionId", newJString(RevisionId))
  add(path_606433, "DataSetId", newJString(DataSetId))
  result = call_606432.call(path_606433, nil, nil, nil, nil)

var getRevision* = Call_GetRevision_606419(name: "getRevision",
                                        meth: HttpMethod.HttpGet,
                                        host: "dataexchange.amazonaws.com", route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}",
                                        validator: validate_GetRevision_606420,
                                        base: "/", url: url_GetRevision_606421,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRevision_606449 = ref object of OpenApiRestCall_605589
proc url_UpdateRevision_606451(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRevision_606450(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## This operation updates a revision.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_606452 = path.getOrDefault("RevisionId")
  valid_606452 = validateParameter(valid_606452, JString, required = true,
                                 default = nil)
  if valid_606452 != nil:
    section.add "RevisionId", valid_606452
  var valid_606453 = path.getOrDefault("DataSetId")
  valid_606453 = validateParameter(valid_606453, JString, required = true,
                                 default = nil)
  if valid_606453 != nil:
    section.add "DataSetId", valid_606453
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
  var valid_606454 = header.getOrDefault("X-Amz-Signature")
  valid_606454 = validateParameter(valid_606454, JString, required = false,
                                 default = nil)
  if valid_606454 != nil:
    section.add "X-Amz-Signature", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Content-Sha256", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Date")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Date", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Credential")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Credential", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Security-Token")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Security-Token", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Algorithm")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Algorithm", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-SignedHeaders", valid_606460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606462: Call_UpdateRevision_606449; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation updates a revision.
  ## 
  let valid = call_606462.validator(path, query, header, formData, body)
  let scheme = call_606462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606462.url(scheme.get, call_606462.host, call_606462.base,
                         call_606462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606462, url, valid)

proc call*(call_606463: Call_UpdateRevision_606449; RevisionId: string;
          DataSetId: string; body: JsonNode): Recallable =
  ## updateRevision
  ## This operation updates a revision.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   body: JObject (required)
  var path_606464 = newJObject()
  var body_606465 = newJObject()
  add(path_606464, "RevisionId", newJString(RevisionId))
  add(path_606464, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_606465 = body
  result = call_606463.call(path_606464, nil, nil, nil, body_606465)

var updateRevision* = Call_UpdateRevision_606449(name: "updateRevision",
    meth: HttpMethod.HttpPatch, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}",
    validator: validate_UpdateRevision_606450, base: "/", url: url_UpdateRevision_606451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRevision_606434 = ref object of OpenApiRestCall_605589
proc url_DeleteRevision_606436(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRevision_606435(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## This operation deletes a revision.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_606437 = path.getOrDefault("RevisionId")
  valid_606437 = validateParameter(valid_606437, JString, required = true,
                                 default = nil)
  if valid_606437 != nil:
    section.add "RevisionId", valid_606437
  var valid_606438 = path.getOrDefault("DataSetId")
  valid_606438 = validateParameter(valid_606438, JString, required = true,
                                 default = nil)
  if valid_606438 != nil:
    section.add "DataSetId", valid_606438
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
  var valid_606439 = header.getOrDefault("X-Amz-Signature")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-Signature", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Content-Sha256", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Date")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Date", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Credential")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Credential", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Security-Token")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Security-Token", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Algorithm")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Algorithm", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-SignedHeaders", valid_606445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606446: Call_DeleteRevision_606434; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation deletes a revision.
  ## 
  let valid = call_606446.validator(path, query, header, formData, body)
  let scheme = call_606446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606446.url(scheme.get, call_606446.host, call_606446.base,
                         call_606446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606446, url, valid)

proc call*(call_606447: Call_DeleteRevision_606434; RevisionId: string;
          DataSetId: string): Recallable =
  ## deleteRevision
  ## This operation deletes a revision.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_606448 = newJObject()
  add(path_606448, "RevisionId", newJString(RevisionId))
  add(path_606448, "DataSetId", newJString(DataSetId))
  result = call_606447.call(path_606448, nil, nil, nil, nil)

var deleteRevision* = Call_DeleteRevision_606434(name: "deleteRevision",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}",
    validator: validate_DeleteRevision_606435, base: "/", url: url_DeleteRevision_606436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRevisionAssets_606466 = ref object of OpenApiRestCall_605589
proc url_ListRevisionAssets_606468(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId"),
               (kind: ConstantSegment, value: "/assets")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRevisionAssets_606467(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## This operation lists a revision's assets sorted alphabetically in descending order.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_606469 = path.getOrDefault("RevisionId")
  valid_606469 = validateParameter(valid_606469, JString, required = true,
                                 default = nil)
  if valid_606469 != nil:
    section.add "RevisionId", valid_606469
  var valid_606470 = path.getOrDefault("DataSetId")
  valid_606470 = validateParameter(valid_606470, JString, required = true,
                                 default = nil)
  if valid_606470 != nil:
    section.add "DataSetId", valid_606470
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results returned by a single call.
  section = newJObject()
  var valid_606471 = query.getOrDefault("nextToken")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "nextToken", valid_606471
  var valid_606472 = query.getOrDefault("MaxResults")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "MaxResults", valid_606472
  var valid_606473 = query.getOrDefault("NextToken")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "NextToken", valid_606473
  var valid_606474 = query.getOrDefault("maxResults")
  valid_606474 = validateParameter(valid_606474, JInt, required = false, default = nil)
  if valid_606474 != nil:
    section.add "maxResults", valid_606474
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
  var valid_606475 = header.getOrDefault("X-Amz-Signature")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Signature", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Content-Sha256", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-Date")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Date", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-Credential")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-Credential", valid_606478
  var valid_606479 = header.getOrDefault("X-Amz-Security-Token")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-Security-Token", valid_606479
  var valid_606480 = header.getOrDefault("X-Amz-Algorithm")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-Algorithm", valid_606480
  var valid_606481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-SignedHeaders", valid_606481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606482: Call_ListRevisionAssets_606466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists a revision's assets sorted alphabetically in descending order.
  ## 
  let valid = call_606482.validator(path, query, header, formData, body)
  let scheme = call_606482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606482.url(scheme.get, call_606482.host, call_606482.base,
                         call_606482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606482, url, valid)

proc call*(call_606483: Call_ListRevisionAssets_606466; RevisionId: string;
          DataSetId: string; nextToken: string = ""; MaxResults: string = "";
          NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listRevisionAssets
  ## This operation lists a revision's assets sorted alphabetically in descending order.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   nextToken: string
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   maxResults: int
  ##             : The maximum number of results returned by a single call.
  var path_606484 = newJObject()
  var query_606485 = newJObject()
  add(path_606484, "RevisionId", newJString(RevisionId))
  add(query_606485, "nextToken", newJString(nextToken))
  add(query_606485, "MaxResults", newJString(MaxResults))
  add(query_606485, "NextToken", newJString(NextToken))
  add(path_606484, "DataSetId", newJString(DataSetId))
  add(query_606485, "maxResults", newJInt(maxResults))
  result = call_606483.call(path_606484, query_606485, nil, nil, nil)

var listRevisionAssets* = Call_ListRevisionAssets_606466(
    name: "listRevisionAssets", meth: HttpMethod.HttpGet,
    host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets",
    validator: validate_ListRevisionAssets_606467, base: "/",
    url: url_ListRevisionAssets_606468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606500 = ref object of OpenApiRestCall_605589
proc url_TagResource_606502(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_606501(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation tags a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_606503 = path.getOrDefault("resource-arn")
  valid_606503 = validateParameter(valid_606503, JString, required = true,
                                 default = nil)
  if valid_606503 != nil:
    section.add "resource-arn", valid_606503
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
  var valid_606504 = header.getOrDefault("X-Amz-Signature")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Signature", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Content-Sha256", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-Date")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-Date", valid_606506
  var valid_606507 = header.getOrDefault("X-Amz-Credential")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "X-Amz-Credential", valid_606507
  var valid_606508 = header.getOrDefault("X-Amz-Security-Token")
  valid_606508 = validateParameter(valid_606508, JString, required = false,
                                 default = nil)
  if valid_606508 != nil:
    section.add "X-Amz-Security-Token", valid_606508
  var valid_606509 = header.getOrDefault("X-Amz-Algorithm")
  valid_606509 = validateParameter(valid_606509, JString, required = false,
                                 default = nil)
  if valid_606509 != nil:
    section.add "X-Amz-Algorithm", valid_606509
  var valid_606510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "X-Amz-SignedHeaders", valid_606510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606512: Call_TagResource_606500; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation tags a resource.
  ## 
  let valid = call_606512.validator(path, query, header, formData, body)
  let scheme = call_606512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606512.url(scheme.get, call_606512.host, call_606512.base,
                         call_606512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606512, url, valid)

proc call*(call_606513: Call_TagResource_606500; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## This operation tags a resource.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  ##   body: JObject (required)
  var path_606514 = newJObject()
  var body_606515 = newJObject()
  add(path_606514, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_606515 = body
  result = call_606513.call(path_606514, nil, nil, nil, body_606515)

var tagResource* = Call_TagResource_606500(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "dataexchange.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_606501,
                                        base: "/", url: url_TagResource_606502,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606486 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606488(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_606487(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## This operation lists the tags on the resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_606489 = path.getOrDefault("resource-arn")
  valid_606489 = validateParameter(valid_606489, JString, required = true,
                                 default = nil)
  if valid_606489 != nil:
    section.add "resource-arn", valid_606489
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
  var valid_606490 = header.getOrDefault("X-Amz-Signature")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Signature", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-Content-Sha256", valid_606491
  var valid_606492 = header.getOrDefault("X-Amz-Date")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-Date", valid_606492
  var valid_606493 = header.getOrDefault("X-Amz-Credential")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-Credential", valid_606493
  var valid_606494 = header.getOrDefault("X-Amz-Security-Token")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "X-Amz-Security-Token", valid_606494
  var valid_606495 = header.getOrDefault("X-Amz-Algorithm")
  valid_606495 = validateParameter(valid_606495, JString, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "X-Amz-Algorithm", valid_606495
  var valid_606496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-SignedHeaders", valid_606496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606497: Call_ListTagsForResource_606486; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists the tags on the resource.
  ## 
  let valid = call_606497.validator(path, query, header, formData, body)
  let scheme = call_606497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606497.url(scheme.get, call_606497.host, call_606497.base,
                         call_606497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606497, url, valid)

proc call*(call_606498: Call_ListTagsForResource_606486; resourceArn: string): Recallable =
  ## listTagsForResource
  ## This operation lists the tags on the resource.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  var path_606499 = newJObject()
  add(path_606499, "resource-arn", newJString(resourceArn))
  result = call_606498.call(path_606499, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_606486(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "dataexchange.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_606487, base: "/",
    url: url_ListTagsForResource_606488, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606516 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606518(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn"),
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

proc validate_UntagResource_606517(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation removes one or more tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_606519 = path.getOrDefault("resource-arn")
  valid_606519 = validateParameter(valid_606519, JString, required = true,
                                 default = nil)
  if valid_606519 != nil:
    section.add "resource-arn", valid_606519
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key tags.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_606520 = query.getOrDefault("tagKeys")
  valid_606520 = validateParameter(valid_606520, JArray, required = true, default = nil)
  if valid_606520 != nil:
    section.add "tagKeys", valid_606520
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
  var valid_606521 = header.getOrDefault("X-Amz-Signature")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-Signature", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-Content-Sha256", valid_606522
  var valid_606523 = header.getOrDefault("X-Amz-Date")
  valid_606523 = validateParameter(valid_606523, JString, required = false,
                                 default = nil)
  if valid_606523 != nil:
    section.add "X-Amz-Date", valid_606523
  var valid_606524 = header.getOrDefault("X-Amz-Credential")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "X-Amz-Credential", valid_606524
  var valid_606525 = header.getOrDefault("X-Amz-Security-Token")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "X-Amz-Security-Token", valid_606525
  var valid_606526 = header.getOrDefault("X-Amz-Algorithm")
  valid_606526 = validateParameter(valid_606526, JString, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "X-Amz-Algorithm", valid_606526
  var valid_606527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-SignedHeaders", valid_606527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606528: Call_UntagResource_606516; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation removes one or more tags from a resource.
  ## 
  let valid = call_606528.validator(path, query, header, formData, body)
  let scheme = call_606528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606528.url(scheme.get, call_606528.host, call_606528.base,
                         call_606528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606528, url, valid)

proc call*(call_606529: Call_UntagResource_606516; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## This operation removes one or more tags from a resource.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  ##   tagKeys: JArray (required)
  ##          : The key tags.
  var path_606530 = newJObject()
  var query_606531 = newJObject()
  add(path_606530, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_606531.add "tagKeys", tagKeys
  result = call_606529.call(path_606530, query_606531, nil, nil, nil)

var untagResource* = Call_UntagResource_606516(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_606517,
    base: "/", url: url_UntagResource_606518, schemes: {Scheme.Https, Scheme.Http})
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
