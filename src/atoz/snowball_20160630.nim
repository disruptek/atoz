
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Import/Export Snowball
## version: 2016-06-30
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS Snowball is a petabyte-scale data transport solution that uses secure devices to transfer large amounts of data between your on-premises data centers and Amazon Simple Storage Service (Amazon S3). The commands described here provide access to the same functionality that is available in the AWS Snowball Management Console, which enables you to create and manage jobs for Snowball and Snowball Edge devices. To transfer data locally with a device, you'll need to use the Snowball client or the Amazon S3 API adapter for Snowball.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/snowball/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "snowball.ap-northeast-1.amazonaws.com", "ap-southeast-1": "snowball.ap-southeast-1.amazonaws.com",
                           "us-west-2": "snowball.us-west-2.amazonaws.com",
                           "eu-west-2": "snowball.eu-west-2.amazonaws.com", "ap-northeast-3": "snowball.ap-northeast-3.amazonaws.com", "eu-central-1": "snowball.eu-central-1.amazonaws.com",
                           "us-east-2": "snowball.us-east-2.amazonaws.com",
                           "us-east-1": "snowball.us-east-1.amazonaws.com", "cn-northwest-1": "snowball.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "snowball.ap-south-1.amazonaws.com",
                           "eu-north-1": "snowball.eu-north-1.amazonaws.com", "ap-northeast-2": "snowball.ap-northeast-2.amazonaws.com",
                           "us-west-1": "snowball.us-west-1.amazonaws.com", "us-gov-east-1": "snowball.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "snowball.eu-west-3.amazonaws.com", "cn-north-1": "snowball.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "snowball.sa-east-1.amazonaws.com",
                           "eu-west-1": "snowball.eu-west-1.amazonaws.com", "us-gov-west-1": "snowball.us-gov-west-1.amazonaws.com", "ap-southeast-2": "snowball.ap-southeast-2.amazonaws.com", "ca-central-1": "snowball.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "snowball.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "snowball.ap-southeast-1.amazonaws.com",
      "us-west-2": "snowball.us-west-2.amazonaws.com",
      "eu-west-2": "snowball.eu-west-2.amazonaws.com",
      "ap-northeast-3": "snowball.ap-northeast-3.amazonaws.com",
      "eu-central-1": "snowball.eu-central-1.amazonaws.com",
      "us-east-2": "snowball.us-east-2.amazonaws.com",
      "us-east-1": "snowball.us-east-1.amazonaws.com",
      "cn-northwest-1": "snowball.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "snowball.ap-south-1.amazonaws.com",
      "eu-north-1": "snowball.eu-north-1.amazonaws.com",
      "ap-northeast-2": "snowball.ap-northeast-2.amazonaws.com",
      "us-west-1": "snowball.us-west-1.amazonaws.com",
      "us-gov-east-1": "snowball.us-gov-east-1.amazonaws.com",
      "eu-west-3": "snowball.eu-west-3.amazonaws.com",
      "cn-north-1": "snowball.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "snowball.sa-east-1.amazonaws.com",
      "eu-west-1": "snowball.eu-west-1.amazonaws.com",
      "us-gov-west-1": "snowball.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "snowball.ap-southeast-2.amazonaws.com",
      "ca-central-1": "snowball.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "snowball"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CancelCluster_600768 = ref object of OpenApiRestCall_600426
proc url_CancelCluster_600770(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CancelCluster_600769(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Cancels a cluster job. You can only cancel a cluster job while it's in the <code>AwaitingQuorum</code> status. You'll have at least an hour after creating a cluster job to cancel it.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600897 = header.getOrDefault("X-Amz-Target")
  valid_600897 = validateParameter(valid_600897, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CancelCluster"))
  if valid_600897 != nil:
    section.add "X-Amz-Target", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Content-Sha256", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Algorithm")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Algorithm", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Signature")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Signature", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-SignedHeaders", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Credential")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Credential", valid_600902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_CancelCluster_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels a cluster job. You can only cancel a cluster job while it's in the <code>AwaitingQuorum</code> status. You'll have at least an hour after creating a cluster job to cancel it.
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"))
  result = hook(call_600926, url, valid)

proc call*(call_600997: Call_CancelCluster_600768; body: JsonNode): Recallable =
  ## cancelCluster
  ## Cancels a cluster job. You can only cancel a cluster job while it's in the <code>AwaitingQuorum</code> status. You'll have at least an hour after creating a cluster job to cancel it.
  ##   body: JObject (required)
  var body_600998 = newJObject()
  if body != nil:
    body_600998 = body
  result = call_600997.call(nil, nil, nil, nil, body_600998)

var cancelCluster* = Call_CancelCluster_600768(name: "cancelCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CancelCluster",
    validator: validate_CancelCluster_600769, base: "/", url: url_CancelCluster_600770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_601037 = ref object of OpenApiRestCall_600426
proc url_CancelJob_601039(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CancelJob_601038(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Cancels the specified job. You can only cancel a job before its <code>JobState</code> value changes to <code>PreparingAppliance</code>. Requesting the <code>ListJobs</code> or <code>DescribeJob</code> action returns a job's <code>JobState</code> as part of the response element data returned.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601040 = header.getOrDefault("X-Amz-Date")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Date", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Security-Token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Security-Token", valid_601041
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601042 = header.getOrDefault("X-Amz-Target")
  valid_601042 = validateParameter(valid_601042, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CancelJob"))
  if valid_601042 != nil:
    section.add "X-Amz-Target", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Content-Sha256", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Algorithm")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Algorithm", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Signature")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Signature", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-SignedHeaders", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Credential")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Credential", valid_601047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601049: Call_CancelJob_601037; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the specified job. You can only cancel a job before its <code>JobState</code> value changes to <code>PreparingAppliance</code>. Requesting the <code>ListJobs</code> or <code>DescribeJob</code> action returns a job's <code>JobState</code> as part of the response element data returned.
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"))
  result = hook(call_601049, url, valid)

proc call*(call_601050: Call_CancelJob_601037; body: JsonNode): Recallable =
  ## cancelJob
  ## Cancels the specified job. You can only cancel a job before its <code>JobState</code> value changes to <code>PreparingAppliance</code>. Requesting the <code>ListJobs</code> or <code>DescribeJob</code> action returns a job's <code>JobState</code> as part of the response element data returned.
  ##   body: JObject (required)
  var body_601051 = newJObject()
  if body != nil:
    body_601051 = body
  result = call_601050.call(nil, nil, nil, nil, body_601051)

var cancelJob* = Call_CancelJob_601037(name: "cancelJob", meth: HttpMethod.HttpPost,
                                    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CancelJob",
                                    validator: validate_CancelJob_601038,
                                    base: "/", url: url_CancelJob_601039,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAddress_601052 = ref object of OpenApiRestCall_600426
proc url_CreateAddress_601054(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateAddress_601053(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an address for a Snowball to be shipped to. In most regions, addresses are validated at the time of creation. The address you provide must be located within the serviceable area of your region. If the address is invalid or unsupported, then an exception is thrown.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601057 = header.getOrDefault("X-Amz-Target")
  valid_601057 = validateParameter(valid_601057, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CreateAddress"))
  if valid_601057 != nil:
    section.add "X-Amz-Target", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601064: Call_CreateAddress_601052; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an address for a Snowball to be shipped to. In most regions, addresses are validated at the time of creation. The address you provide must be located within the serviceable area of your region. If the address is invalid or unsupported, then an exception is thrown.
  ## 
  let valid = call_601064.validator(path, query, header, formData, body)
  let scheme = call_601064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601064.url(scheme.get, call_601064.host, call_601064.base,
                         call_601064.route, valid.getOrDefault("path"))
  result = hook(call_601064, url, valid)

proc call*(call_601065: Call_CreateAddress_601052; body: JsonNode): Recallable =
  ## createAddress
  ## Creates an address for a Snowball to be shipped to. In most regions, addresses are validated at the time of creation. The address you provide must be located within the serviceable area of your region. If the address is invalid or unsupported, then an exception is thrown.
  ##   body: JObject (required)
  var body_601066 = newJObject()
  if body != nil:
    body_601066 = body
  result = call_601065.call(nil, nil, nil, nil, body_601066)

var createAddress* = Call_CreateAddress_601052(name: "createAddress",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CreateAddress",
    validator: validate_CreateAddress_601053, base: "/", url: url_CreateAddress_601054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCluster_601067 = ref object of OpenApiRestCall_600426
proc url_CreateCluster_601069(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateCluster_601068(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an empty cluster. Each cluster supports five nodes. You use the <a>CreateJob</a> action separately to create the jobs for each of these nodes. The cluster does not ship until these five node jobs have been created.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601070 = header.getOrDefault("X-Amz-Date")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Date", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Security-Token")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Security-Token", valid_601071
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601072 = header.getOrDefault("X-Amz-Target")
  valid_601072 = validateParameter(valid_601072, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CreateCluster"))
  if valid_601072 != nil:
    section.add "X-Amz-Target", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Content-Sha256", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Algorithm")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Algorithm", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Signature")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Signature", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-SignedHeaders", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Credential")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Credential", valid_601077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601079: Call_CreateCluster_601067; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an empty cluster. Each cluster supports five nodes. You use the <a>CreateJob</a> action separately to create the jobs for each of these nodes. The cluster does not ship until these five node jobs have been created.
  ## 
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"))
  result = hook(call_601079, url, valid)

proc call*(call_601080: Call_CreateCluster_601067; body: JsonNode): Recallable =
  ## createCluster
  ## Creates an empty cluster. Each cluster supports five nodes. You use the <a>CreateJob</a> action separately to create the jobs for each of these nodes. The cluster does not ship until these five node jobs have been created.
  ##   body: JObject (required)
  var body_601081 = newJObject()
  if body != nil:
    body_601081 = body
  result = call_601080.call(nil, nil, nil, nil, body_601081)

var createCluster* = Call_CreateCluster_601067(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CreateCluster",
    validator: validate_CreateCluster_601068, base: "/", url: url_CreateCluster_601069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_601082 = ref object of OpenApiRestCall_600426
proc url_CreateJob_601084(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateJob_601083(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a job to import or export data between Amazon S3 and your on-premises data center. Your AWS account must have the right trust policies and permissions in place to create a job for Snowball. If you're creating a job for a node in a cluster, you only need to provide the <code>clusterId</code> value; the other job attributes are inherited from the cluster. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601085 = header.getOrDefault("X-Amz-Date")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Date", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Security-Token")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Security-Token", valid_601086
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601087 = header.getOrDefault("X-Amz-Target")
  valid_601087 = validateParameter(valid_601087, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CreateJob"))
  if valid_601087 != nil:
    section.add "X-Amz-Target", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Content-Sha256", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Algorithm")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Algorithm", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Signature")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Signature", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-SignedHeaders", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Credential")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Credential", valid_601092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601094: Call_CreateJob_601082; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a job to import or export data between Amazon S3 and your on-premises data center. Your AWS account must have the right trust policies and permissions in place to create a job for Snowball. If you're creating a job for a node in a cluster, you only need to provide the <code>clusterId</code> value; the other job attributes are inherited from the cluster. 
  ## 
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"))
  result = hook(call_601094, url, valid)

proc call*(call_601095: Call_CreateJob_601082; body: JsonNode): Recallable =
  ## createJob
  ## Creates a job to import or export data between Amazon S3 and your on-premises data center. Your AWS account must have the right trust policies and permissions in place to create a job for Snowball. If you're creating a job for a node in a cluster, you only need to provide the <code>clusterId</code> value; the other job attributes are inherited from the cluster. 
  ##   body: JObject (required)
  var body_601096 = newJObject()
  if body != nil:
    body_601096 = body
  result = call_601095.call(nil, nil, nil, nil, body_601096)

var createJob* = Call_CreateJob_601082(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CreateJob",
                                    validator: validate_CreateJob_601083,
                                    base: "/", url: url_CreateJob_601084,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAddress_601097 = ref object of OpenApiRestCall_600426
proc url_DescribeAddress_601099(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAddress_601098(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Takes an <code>AddressId</code> and returns specific details about that address in the form of an <code>Address</code> object.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601100 = header.getOrDefault("X-Amz-Date")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Date", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Security-Token")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Security-Token", valid_601101
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601102 = header.getOrDefault("X-Amz-Target")
  valid_601102 = validateParameter(valid_601102, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeAddress"))
  if valid_601102 != nil:
    section.add "X-Amz-Target", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Content-Sha256", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Algorithm")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Algorithm", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Signature")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Signature", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-SignedHeaders", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Credential")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Credential", valid_601107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601109: Call_DescribeAddress_601097; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Takes an <code>AddressId</code> and returns specific details about that address in the form of an <code>Address</code> object.
  ## 
  let valid = call_601109.validator(path, query, header, formData, body)
  let scheme = call_601109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601109.url(scheme.get, call_601109.host, call_601109.base,
                         call_601109.route, valid.getOrDefault("path"))
  result = hook(call_601109, url, valid)

proc call*(call_601110: Call_DescribeAddress_601097; body: JsonNode): Recallable =
  ## describeAddress
  ## Takes an <code>AddressId</code> and returns specific details about that address in the form of an <code>Address</code> object.
  ##   body: JObject (required)
  var body_601111 = newJObject()
  if body != nil:
    body_601111 = body
  result = call_601110.call(nil, nil, nil, nil, body_601111)

var describeAddress* = Call_DescribeAddress_601097(name: "describeAddress",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeAddress",
    validator: validate_DescribeAddress_601098, base: "/", url: url_DescribeAddress_601099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAddresses_601112 = ref object of OpenApiRestCall_600426
proc url_DescribeAddresses_601114(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeAddresses_601113(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns a specified number of <code>ADDRESS</code> objects. Calling this API in one of the US regions will return addresses from the list of all addresses associated with this account in all US regions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601115 = query.getOrDefault("NextToken")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "NextToken", valid_601115
  var valid_601116 = query.getOrDefault("MaxResults")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "MaxResults", valid_601116
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601117 = header.getOrDefault("X-Amz-Date")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-Date", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Security-Token")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Security-Token", valid_601118
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601119 = header.getOrDefault("X-Amz-Target")
  valid_601119 = validateParameter(valid_601119, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeAddresses"))
  if valid_601119 != nil:
    section.add "X-Amz-Target", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Content-Sha256", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Algorithm")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Algorithm", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Signature")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Signature", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-SignedHeaders", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Credential")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Credential", valid_601124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601126: Call_DescribeAddresses_601112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a specified number of <code>ADDRESS</code> objects. Calling this API in one of the US regions will return addresses from the list of all addresses associated with this account in all US regions.
  ## 
  let valid = call_601126.validator(path, query, header, formData, body)
  let scheme = call_601126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601126.url(scheme.get, call_601126.host, call_601126.base,
                         call_601126.route, valid.getOrDefault("path"))
  result = hook(call_601126, url, valid)

proc call*(call_601127: Call_DescribeAddresses_601112; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeAddresses
  ## Returns a specified number of <code>ADDRESS</code> objects. Calling this API in one of the US regions will return addresses from the list of all addresses associated with this account in all US regions.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601128 = newJObject()
  var body_601129 = newJObject()
  add(query_601128, "NextToken", newJString(NextToken))
  if body != nil:
    body_601129 = body
  add(query_601128, "MaxResults", newJString(MaxResults))
  result = call_601127.call(nil, query_601128, nil, nil, body_601129)

var describeAddresses* = Call_DescribeAddresses_601112(name: "describeAddresses",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeAddresses",
    validator: validate_DescribeAddresses_601113, base: "/",
    url: url_DescribeAddresses_601114, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCluster_601131 = ref object of OpenApiRestCall_600426
proc url_DescribeCluster_601133(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeCluster_601132(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns information about a specific cluster including shipping information, cluster status, and other important metadata.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601134 = header.getOrDefault("X-Amz-Date")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Date", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Security-Token")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Security-Token", valid_601135
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601136 = header.getOrDefault("X-Amz-Target")
  valid_601136 = validateParameter(valid_601136, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeCluster"))
  if valid_601136 != nil:
    section.add "X-Amz-Target", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Content-Sha256", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-Algorithm")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-Algorithm", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Signature")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Signature", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-SignedHeaders", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Credential")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Credential", valid_601141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601143: Call_DescribeCluster_601131; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific cluster including shipping information, cluster status, and other important metadata.
  ## 
  let valid = call_601143.validator(path, query, header, formData, body)
  let scheme = call_601143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601143.url(scheme.get, call_601143.host, call_601143.base,
                         call_601143.route, valid.getOrDefault("path"))
  result = hook(call_601143, url, valid)

proc call*(call_601144: Call_DescribeCluster_601131; body: JsonNode): Recallable =
  ## describeCluster
  ## Returns information about a specific cluster including shipping information, cluster status, and other important metadata.
  ##   body: JObject (required)
  var body_601145 = newJObject()
  if body != nil:
    body_601145 = body
  result = call_601144.call(nil, nil, nil, nil, body_601145)

var describeCluster* = Call_DescribeCluster_601131(name: "describeCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeCluster",
    validator: validate_DescribeCluster_601132, base: "/", url: url_DescribeCluster_601133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJob_601146 = ref object of OpenApiRestCall_600426
proc url_DescribeJob_601148(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeJob_601147(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a specific job including shipping information, job status, and other important metadata. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601149 = header.getOrDefault("X-Amz-Date")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Date", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Security-Token")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Security-Token", valid_601150
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601151 = header.getOrDefault("X-Amz-Target")
  valid_601151 = validateParameter(valid_601151, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeJob"))
  if valid_601151 != nil:
    section.add "X-Amz-Target", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Content-Sha256", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Algorithm")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Algorithm", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Signature")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Signature", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-SignedHeaders", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Credential")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Credential", valid_601156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601158: Call_DescribeJob_601146; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific job including shipping information, job status, and other important metadata. 
  ## 
  let valid = call_601158.validator(path, query, header, formData, body)
  let scheme = call_601158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601158.url(scheme.get, call_601158.host, call_601158.base,
                         call_601158.route, valid.getOrDefault("path"))
  result = hook(call_601158, url, valid)

proc call*(call_601159: Call_DescribeJob_601146; body: JsonNode): Recallable =
  ## describeJob
  ## Returns information about a specific job including shipping information, job status, and other important metadata. 
  ##   body: JObject (required)
  var body_601160 = newJObject()
  if body != nil:
    body_601160 = body
  result = call_601159.call(nil, nil, nil, nil, body_601160)

var describeJob* = Call_DescribeJob_601146(name: "describeJob",
                                        meth: HttpMethod.HttpPost,
                                        host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeJob",
                                        validator: validate_DescribeJob_601147,
                                        base: "/", url: url_DescribeJob_601148,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobManifest_601161 = ref object of OpenApiRestCall_600426
proc url_GetJobManifest_601163(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetJobManifest_601162(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns a link to an Amazon S3 presigned URL for the manifest file associated with the specified <code>JobId</code> value. You can access the manifest file for up to 60 minutes after this request has been made. To access the manifest file after 60 minutes have passed, you'll have to make another call to the <code>GetJobManifest</code> action.</p> <p>The manifest is an encrypted file that you can download after your job enters the <code>WithCustomer</code> status. The manifest is decrypted by using the <code>UnlockCode</code> code value, when you pass both values to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of an <code>UnlockCode</code> value in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p> <p>The credentials of a given job, including its manifest file and unlock code, expire 90 days after the job is created.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601164 = header.getOrDefault("X-Amz-Date")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Date", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Security-Token")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Security-Token", valid_601165
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601166 = header.getOrDefault("X-Amz-Target")
  valid_601166 = validateParameter(valid_601166, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.GetJobManifest"))
  if valid_601166 != nil:
    section.add "X-Amz-Target", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Content-Sha256", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Algorithm")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Algorithm", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Signature")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Signature", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-SignedHeaders", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Credential")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Credential", valid_601171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601173: Call_GetJobManifest_601161; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a link to an Amazon S3 presigned URL for the manifest file associated with the specified <code>JobId</code> value. You can access the manifest file for up to 60 minutes after this request has been made. To access the manifest file after 60 minutes have passed, you'll have to make another call to the <code>GetJobManifest</code> action.</p> <p>The manifest is an encrypted file that you can download after your job enters the <code>WithCustomer</code> status. The manifest is decrypted by using the <code>UnlockCode</code> code value, when you pass both values to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of an <code>UnlockCode</code> value in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p> <p>The credentials of a given job, including its manifest file and unlock code, expire 90 days after the job is created.</p>
  ## 
  let valid = call_601173.validator(path, query, header, formData, body)
  let scheme = call_601173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601173.url(scheme.get, call_601173.host, call_601173.base,
                         call_601173.route, valid.getOrDefault("path"))
  result = hook(call_601173, url, valid)

proc call*(call_601174: Call_GetJobManifest_601161; body: JsonNode): Recallable =
  ## getJobManifest
  ## <p>Returns a link to an Amazon S3 presigned URL for the manifest file associated with the specified <code>JobId</code> value. You can access the manifest file for up to 60 minutes after this request has been made. To access the manifest file after 60 minutes have passed, you'll have to make another call to the <code>GetJobManifest</code> action.</p> <p>The manifest is an encrypted file that you can download after your job enters the <code>WithCustomer</code> status. The manifest is decrypted by using the <code>UnlockCode</code> code value, when you pass both values to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of an <code>UnlockCode</code> value in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p> <p>The credentials of a given job, including its manifest file and unlock code, expire 90 days after the job is created.</p>
  ##   body: JObject (required)
  var body_601175 = newJObject()
  if body != nil:
    body_601175 = body
  result = call_601174.call(nil, nil, nil, nil, body_601175)

var getJobManifest* = Call_GetJobManifest_601161(name: "getJobManifest",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.GetJobManifest",
    validator: validate_GetJobManifest_601162, base: "/", url: url_GetJobManifest_601163,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobUnlockCode_601176 = ref object of OpenApiRestCall_600426
proc url_GetJobUnlockCode_601178(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetJobUnlockCode_601177(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Returns the <code>UnlockCode</code> code value for the specified job. A particular <code>UnlockCode</code> value can be accessed for up to 90 days after the associated job has been created.</p> <p>The <code>UnlockCode</code> value is a 29-character code with 25 alphanumeric characters and 4 hyphens. This code is used to decrypt the manifest file when it is passed along with the manifest to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of the <code>UnlockCode</code> in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601179 = header.getOrDefault("X-Amz-Date")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Date", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Security-Token")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Security-Token", valid_601180
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601181 = header.getOrDefault("X-Amz-Target")
  valid_601181 = validateParameter(valid_601181, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.GetJobUnlockCode"))
  if valid_601181 != nil:
    section.add "X-Amz-Target", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Content-Sha256", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Algorithm")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Algorithm", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Signature")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Signature", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-SignedHeaders", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Credential")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Credential", valid_601186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601188: Call_GetJobUnlockCode_601176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the <code>UnlockCode</code> code value for the specified job. A particular <code>UnlockCode</code> value can be accessed for up to 90 days after the associated job has been created.</p> <p>The <code>UnlockCode</code> value is a 29-character code with 25 alphanumeric characters and 4 hyphens. This code is used to decrypt the manifest file when it is passed along with the manifest to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of the <code>UnlockCode</code> in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p>
  ## 
  let valid = call_601188.validator(path, query, header, formData, body)
  let scheme = call_601188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601188.url(scheme.get, call_601188.host, call_601188.base,
                         call_601188.route, valid.getOrDefault("path"))
  result = hook(call_601188, url, valid)

proc call*(call_601189: Call_GetJobUnlockCode_601176; body: JsonNode): Recallable =
  ## getJobUnlockCode
  ## <p>Returns the <code>UnlockCode</code> code value for the specified job. A particular <code>UnlockCode</code> value can be accessed for up to 90 days after the associated job has been created.</p> <p>The <code>UnlockCode</code> value is a 29-character code with 25 alphanumeric characters and 4 hyphens. This code is used to decrypt the manifest file when it is passed along with the manifest to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of the <code>UnlockCode</code> in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p>
  ##   body: JObject (required)
  var body_601190 = newJObject()
  if body != nil:
    body_601190 = body
  result = call_601189.call(nil, nil, nil, nil, body_601190)

var getJobUnlockCode* = Call_GetJobUnlockCode_601176(name: "getJobUnlockCode",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.GetJobUnlockCode",
    validator: validate_GetJobUnlockCode_601177, base: "/",
    url: url_GetJobUnlockCode_601178, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSnowballUsage_601191 = ref object of OpenApiRestCall_600426
proc url_GetSnowballUsage_601193(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSnowballUsage_601192(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Returns information about the Snowball service limit for your account, and also the number of Snowballs your account has in use.</p> <p>The default service limit for the number of Snowballs that you can have at one time is 1. If you want to increase your service limit, contact AWS Support.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601194 = header.getOrDefault("X-Amz-Date")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Date", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Security-Token")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Security-Token", valid_601195
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601196 = header.getOrDefault("X-Amz-Target")
  valid_601196 = validateParameter(valid_601196, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.GetSnowballUsage"))
  if valid_601196 != nil:
    section.add "X-Amz-Target", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Content-Sha256", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Algorithm")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Algorithm", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Signature")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Signature", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-SignedHeaders", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Credential")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Credential", valid_601201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601203: Call_GetSnowballUsage_601191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the Snowball service limit for your account, and also the number of Snowballs your account has in use.</p> <p>The default service limit for the number of Snowballs that you can have at one time is 1. If you want to increase your service limit, contact AWS Support.</p>
  ## 
  let valid = call_601203.validator(path, query, header, formData, body)
  let scheme = call_601203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601203.url(scheme.get, call_601203.host, call_601203.base,
                         call_601203.route, valid.getOrDefault("path"))
  result = hook(call_601203, url, valid)

proc call*(call_601204: Call_GetSnowballUsage_601191; body: JsonNode): Recallable =
  ## getSnowballUsage
  ## <p>Returns information about the Snowball service limit for your account, and also the number of Snowballs your account has in use.</p> <p>The default service limit for the number of Snowballs that you can have at one time is 1. If you want to increase your service limit, contact AWS Support.</p>
  ##   body: JObject (required)
  var body_601205 = newJObject()
  if body != nil:
    body_601205 = body
  result = call_601204.call(nil, nil, nil, nil, body_601205)

var getSnowballUsage* = Call_GetSnowballUsage_601191(name: "getSnowballUsage",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.GetSnowballUsage",
    validator: validate_GetSnowballUsage_601192, base: "/",
    url: url_GetSnowballUsage_601193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusterJobs_601206 = ref object of OpenApiRestCall_600426
proc url_ListClusterJobs_601208(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListClusterJobs_601207(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object is for a job in the specified cluster and contains a job's state, a job's ID, and other information.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601209 = header.getOrDefault("X-Amz-Date")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Date", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Security-Token")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Security-Token", valid_601210
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601211 = header.getOrDefault("X-Amz-Target")
  valid_601211 = validateParameter(valid_601211, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListClusterJobs"))
  if valid_601211 != nil:
    section.add "X-Amz-Target", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Content-Sha256", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-Algorithm")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Algorithm", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Signature")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Signature", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-SignedHeaders", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Credential")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Credential", valid_601216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601218: Call_ListClusterJobs_601206; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object is for a job in the specified cluster and contains a job's state, a job's ID, and other information.
  ## 
  let valid = call_601218.validator(path, query, header, formData, body)
  let scheme = call_601218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601218.url(scheme.get, call_601218.host, call_601218.base,
                         call_601218.route, valid.getOrDefault("path"))
  result = hook(call_601218, url, valid)

proc call*(call_601219: Call_ListClusterJobs_601206; body: JsonNode): Recallable =
  ## listClusterJobs
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object is for a job in the specified cluster and contains a job's state, a job's ID, and other information.
  ##   body: JObject (required)
  var body_601220 = newJObject()
  if body != nil:
    body_601220 = body
  result = call_601219.call(nil, nil, nil, nil, body_601220)

var listClusterJobs* = Call_ListClusterJobs_601206(name: "listClusterJobs",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListClusterJobs",
    validator: validate_ListClusterJobs_601207, base: "/", url: url_ListClusterJobs_601208,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_601221 = ref object of OpenApiRestCall_600426
proc url_ListClusters_601223(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListClusters_601222(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of <code>ClusterListEntry</code> objects of the specified length. Each <code>ClusterListEntry</code> object contains a cluster's state, a cluster's ID, and other important status information.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601224 = header.getOrDefault("X-Amz-Date")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Date", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-Security-Token")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Security-Token", valid_601225
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601226 = header.getOrDefault("X-Amz-Target")
  valid_601226 = validateParameter(valid_601226, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListClusters"))
  if valid_601226 != nil:
    section.add "X-Amz-Target", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Content-Sha256", valid_601227
  var valid_601228 = header.getOrDefault("X-Amz-Algorithm")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Algorithm", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Signature")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Signature", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-SignedHeaders", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Credential")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Credential", valid_601231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601233: Call_ListClusters_601221; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>ClusterListEntry</code> objects of the specified length. Each <code>ClusterListEntry</code> object contains a cluster's state, a cluster's ID, and other important status information.
  ## 
  let valid = call_601233.validator(path, query, header, formData, body)
  let scheme = call_601233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601233.url(scheme.get, call_601233.host, call_601233.base,
                         call_601233.route, valid.getOrDefault("path"))
  result = hook(call_601233, url, valid)

proc call*(call_601234: Call_ListClusters_601221; body: JsonNode): Recallable =
  ## listClusters
  ## Returns an array of <code>ClusterListEntry</code> objects of the specified length. Each <code>ClusterListEntry</code> object contains a cluster's state, a cluster's ID, and other important status information.
  ##   body: JObject (required)
  var body_601235 = newJObject()
  if body != nil:
    body_601235 = body
  result = call_601234.call(nil, nil, nil, nil, body_601235)

var listClusters* = Call_ListClusters_601221(name: "listClusters",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListClusters",
    validator: validate_ListClusters_601222, base: "/", url: url_ListClusters_601223,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCompatibleImages_601236 = ref object of OpenApiRestCall_600426
proc url_ListCompatibleImages_601238(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListCompatibleImages_601237(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This action returns a list of the different Amazon EC2 Amazon Machine Images (AMIs) that are owned by your AWS account that would be supported for use on <code>EDGE</code>, <code>EDGE_C</code>, and <code>EDGE_CG</code> devices. For more information on compatible AMIs, see <a href="http://docs.aws.amazon.com/snowball/latest/developer-guide/using-ec2.html">Using Amazon EC2 Compute Instances</a> in the <i>AWS Snowball Developer Guide</i>.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601239 = header.getOrDefault("X-Amz-Date")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Date", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-Security-Token")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Security-Token", valid_601240
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601241 = header.getOrDefault("X-Amz-Target")
  valid_601241 = validateParameter(valid_601241, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListCompatibleImages"))
  if valid_601241 != nil:
    section.add "X-Amz-Target", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Content-Sha256", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-Algorithm")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Algorithm", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-Signature")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Signature", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-SignedHeaders", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Credential")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Credential", valid_601246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601248: Call_ListCompatibleImages_601236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This action returns a list of the different Amazon EC2 Amazon Machine Images (AMIs) that are owned by your AWS account that would be supported for use on <code>EDGE</code>, <code>EDGE_C</code>, and <code>EDGE_CG</code> devices. For more information on compatible AMIs, see <a href="http://docs.aws.amazon.com/snowball/latest/developer-guide/using-ec2.html">Using Amazon EC2 Compute Instances</a> in the <i>AWS Snowball Developer Guide</i>.
  ## 
  let valid = call_601248.validator(path, query, header, formData, body)
  let scheme = call_601248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601248.url(scheme.get, call_601248.host, call_601248.base,
                         call_601248.route, valid.getOrDefault("path"))
  result = hook(call_601248, url, valid)

proc call*(call_601249: Call_ListCompatibleImages_601236; body: JsonNode): Recallable =
  ## listCompatibleImages
  ## This action returns a list of the different Amazon EC2 Amazon Machine Images (AMIs) that are owned by your AWS account that would be supported for use on <code>EDGE</code>, <code>EDGE_C</code>, and <code>EDGE_CG</code> devices. For more information on compatible AMIs, see <a href="http://docs.aws.amazon.com/snowball/latest/developer-guide/using-ec2.html">Using Amazon EC2 Compute Instances</a> in the <i>AWS Snowball Developer Guide</i>.
  ##   body: JObject (required)
  var body_601250 = newJObject()
  if body != nil:
    body_601250 = body
  result = call_601249.call(nil, nil, nil, nil, body_601250)

var listCompatibleImages* = Call_ListCompatibleImages_601236(
    name: "listCompatibleImages", meth: HttpMethod.HttpPost,
    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListCompatibleImages",
    validator: validate_ListCompatibleImages_601237, base: "/",
    url: url_ListCompatibleImages_601238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_601251 = ref object of OpenApiRestCall_600426
proc url_ListJobs_601253(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListJobs_601252(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object contains a job's state, a job's ID, and a value that indicates whether the job is a job part, in the case of export jobs. Calling this API action in one of the US regions will return jobs from the list of all jobs associated with this account in all US regions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_601254 = query.getOrDefault("NextToken")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "NextToken", valid_601254
  var valid_601255 = query.getOrDefault("MaxResults")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "MaxResults", valid_601255
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601256 = header.getOrDefault("X-Amz-Date")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Date", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Security-Token")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Security-Token", valid_601257
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601258 = header.getOrDefault("X-Amz-Target")
  valid_601258 = validateParameter(valid_601258, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListJobs"))
  if valid_601258 != nil:
    section.add "X-Amz-Target", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Content-Sha256", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Algorithm")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Algorithm", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-Signature")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Signature", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-SignedHeaders", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Credential")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Credential", valid_601263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601265: Call_ListJobs_601251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object contains a job's state, a job's ID, and a value that indicates whether the job is a job part, in the case of export jobs. Calling this API action in one of the US regions will return jobs from the list of all jobs associated with this account in all US regions.
  ## 
  let valid = call_601265.validator(path, query, header, formData, body)
  let scheme = call_601265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601265.url(scheme.get, call_601265.host, call_601265.base,
                         call_601265.route, valid.getOrDefault("path"))
  result = hook(call_601265, url, valid)

proc call*(call_601266: Call_ListJobs_601251; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listJobs
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object contains a job's state, a job's ID, and a value that indicates whether the job is a job part, in the case of export jobs. Calling this API action in one of the US regions will return jobs from the list of all jobs associated with this account in all US regions.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_601267 = newJObject()
  var body_601268 = newJObject()
  add(query_601267, "NextToken", newJString(NextToken))
  if body != nil:
    body_601268 = body
  add(query_601267, "MaxResults", newJString(MaxResults))
  result = call_601266.call(nil, query_601267, nil, nil, body_601268)

var listJobs* = Call_ListJobs_601251(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListJobs",
                                  validator: validate_ListJobs_601252, base: "/",
                                  url: url_ListJobs_601253,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCluster_601269 = ref object of OpenApiRestCall_600426
proc url_UpdateCluster_601271(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateCluster_601270(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## While a cluster's <code>ClusterState</code> value is in the <code>AwaitingQuorum</code> state, you can update some of the information associated with a cluster. Once the cluster changes to a different job state, usually 60 minutes after the cluster being created, this action is no longer available.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601272 = header.getOrDefault("X-Amz-Date")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Date", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Security-Token")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Security-Token", valid_601273
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601274 = header.getOrDefault("X-Amz-Target")
  valid_601274 = validateParameter(valid_601274, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.UpdateCluster"))
  if valid_601274 != nil:
    section.add "X-Amz-Target", valid_601274
  var valid_601275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Content-Sha256", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-Algorithm")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Algorithm", valid_601276
  var valid_601277 = header.getOrDefault("X-Amz-Signature")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "X-Amz-Signature", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-SignedHeaders", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Credential")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Credential", valid_601279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601281: Call_UpdateCluster_601269; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## While a cluster's <code>ClusterState</code> value is in the <code>AwaitingQuorum</code> state, you can update some of the information associated with a cluster. Once the cluster changes to a different job state, usually 60 minutes after the cluster being created, this action is no longer available.
  ## 
  let valid = call_601281.validator(path, query, header, formData, body)
  let scheme = call_601281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601281.url(scheme.get, call_601281.host, call_601281.base,
                         call_601281.route, valid.getOrDefault("path"))
  result = hook(call_601281, url, valid)

proc call*(call_601282: Call_UpdateCluster_601269; body: JsonNode): Recallable =
  ## updateCluster
  ## While a cluster's <code>ClusterState</code> value is in the <code>AwaitingQuorum</code> state, you can update some of the information associated with a cluster. Once the cluster changes to a different job state, usually 60 minutes after the cluster being created, this action is no longer available.
  ##   body: JObject (required)
  var body_601283 = newJObject()
  if body != nil:
    body_601283 = body
  result = call_601282.call(nil, nil, nil, nil, body_601283)

var updateCluster* = Call_UpdateCluster_601269(name: "updateCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.UpdateCluster",
    validator: validate_UpdateCluster_601270, base: "/", url: url_UpdateCluster_601271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJob_601284 = ref object of OpenApiRestCall_600426
proc url_UpdateJob_601286(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateJob_601285(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## While a job's <code>JobState</code> value is <code>New</code>, you can update some of the information associated with a job. Once the job changes to a different job state, usually within 60 minutes of the job being created, this action is no longer available.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601287 = header.getOrDefault("X-Amz-Date")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Date", valid_601287
  var valid_601288 = header.getOrDefault("X-Amz-Security-Token")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Security-Token", valid_601288
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601289 = header.getOrDefault("X-Amz-Target")
  valid_601289 = validateParameter(valid_601289, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.UpdateJob"))
  if valid_601289 != nil:
    section.add "X-Amz-Target", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Content-Sha256", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Algorithm")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Algorithm", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Signature")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Signature", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-SignedHeaders", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Credential")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Credential", valid_601294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601296: Call_UpdateJob_601284; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## While a job's <code>JobState</code> value is <code>New</code>, you can update some of the information associated with a job. Once the job changes to a different job state, usually within 60 minutes of the job being created, this action is no longer available.
  ## 
  let valid = call_601296.validator(path, query, header, formData, body)
  let scheme = call_601296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601296.url(scheme.get, call_601296.host, call_601296.base,
                         call_601296.route, valid.getOrDefault("path"))
  result = hook(call_601296, url, valid)

proc call*(call_601297: Call_UpdateJob_601284; body: JsonNode): Recallable =
  ## updateJob
  ## While a job's <code>JobState</code> value is <code>New</code>, you can update some of the information associated with a job. Once the job changes to a different job state, usually within 60 minutes of the job being created, this action is no longer available.
  ##   body: JObject (required)
  var body_601298 = newJObject()
  if body != nil:
    body_601298 = body
  result = call_601297.call(nil, nil, nil, nil, body_601298)

var updateJob* = Call_UpdateJob_601284(name: "updateJob", meth: HttpMethod.HttpPost,
                                    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.UpdateJob",
                                    validator: validate_UpdateJob_601285,
                                    base: "/", url: url_UpdateJob_601286,
                                    schemes: {Scheme.Https, Scheme.Http})
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
