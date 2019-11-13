
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS CloudTrail
## version: 2013-11-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS CloudTrail</fullname> <p>This is the CloudTrail API Reference. It provides descriptions of actions, data types, common parameters, and common errors for CloudTrail.</p> <p>CloudTrail is a web service that records AWS API calls for your AWS account and delivers log files to an Amazon S3 bucket. The recorded information includes the identity of the user, the start time of the AWS API call, the source IP address, the request parameters, and the response elements returned by the service.</p> <note> <p>As an alternative to the API, you can use one of the AWS SDKs, which consist of libraries and sample code for various programming languages and platforms (Java, Ruby, .NET, iOS, Android, etc.). The SDKs provide a convenient way to create programmatic access to AWSCloudTrail. For example, the SDKs take care of cryptographically signing requests, managing errors, and retrying requests automatically. For information about the AWS SDKs, including how to download and install them, see the <a href="http://aws.amazon.com/tools/">Tools for Amazon Web Services page</a>.</p> </note> <p>See the <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html">AWS CloudTrail User Guide</a> for information about the data that is included with each AWS API call listed in the log files.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudtrail/
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

  OpenApiRestCall_593389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593389): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "cloudtrail.ap-northeast-1.amazonaws.com", "ap-southeast-1": "cloudtrail.ap-southeast-1.amazonaws.com",
                           "us-west-2": "cloudtrail.us-west-2.amazonaws.com",
                           "eu-west-2": "cloudtrail.eu-west-2.amazonaws.com", "ap-northeast-3": "cloudtrail.ap-northeast-3.amazonaws.com", "eu-central-1": "cloudtrail.eu-central-1.amazonaws.com",
                           "us-east-2": "cloudtrail.us-east-2.amazonaws.com",
                           "us-east-1": "cloudtrail.us-east-1.amazonaws.com", "cn-northwest-1": "cloudtrail.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "cloudtrail.ap-south-1.amazonaws.com",
                           "eu-north-1": "cloudtrail.eu-north-1.amazonaws.com", "ap-northeast-2": "cloudtrail.ap-northeast-2.amazonaws.com",
                           "us-west-1": "cloudtrail.us-west-1.amazonaws.com", "us-gov-east-1": "cloudtrail.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "cloudtrail.eu-west-3.amazonaws.com", "cn-north-1": "cloudtrail.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "cloudtrail.sa-east-1.amazonaws.com",
                           "eu-west-1": "cloudtrail.eu-west-1.amazonaws.com", "us-gov-west-1": "cloudtrail.us-gov-west-1.amazonaws.com", "ap-southeast-2": "cloudtrail.ap-southeast-2.amazonaws.com", "ca-central-1": "cloudtrail.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "cloudtrail.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "cloudtrail.ap-southeast-1.amazonaws.com",
      "us-west-2": "cloudtrail.us-west-2.amazonaws.com",
      "eu-west-2": "cloudtrail.eu-west-2.amazonaws.com",
      "ap-northeast-3": "cloudtrail.ap-northeast-3.amazonaws.com",
      "eu-central-1": "cloudtrail.eu-central-1.amazonaws.com",
      "us-east-2": "cloudtrail.us-east-2.amazonaws.com",
      "us-east-1": "cloudtrail.us-east-1.amazonaws.com",
      "cn-northwest-1": "cloudtrail.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "cloudtrail.ap-south-1.amazonaws.com",
      "eu-north-1": "cloudtrail.eu-north-1.amazonaws.com",
      "ap-northeast-2": "cloudtrail.ap-northeast-2.amazonaws.com",
      "us-west-1": "cloudtrail.us-west-1.amazonaws.com",
      "us-gov-east-1": "cloudtrail.us-gov-east-1.amazonaws.com",
      "eu-west-3": "cloudtrail.eu-west-3.amazonaws.com",
      "cn-north-1": "cloudtrail.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "cloudtrail.sa-east-1.amazonaws.com",
      "eu-west-1": "cloudtrail.eu-west-1.amazonaws.com",
      "us-gov-west-1": "cloudtrail.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "cloudtrail.ap-southeast-2.amazonaws.com",
      "ca-central-1": "cloudtrail.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "cloudtrail"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTags_593727 = ref object of OpenApiRestCall_593389
proc url_AddTags_593729(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_AddTags_593728(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds one or more tags to a trail, up to a limit of 50. Overwrites an existing tag's value when a new value is specified for an existing tag key. Tag key names must be unique for a trail; you cannot have two keys with the same name but different values. If you specify a key without a value, the tag will be created with the specified key and a value of null. You can tag a trail that applies to all AWS Regions only from the Region in which the trail was created (also known as its home region).
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593854 = header.getOrDefault("X-Amz-Target")
  valid_593854 = validateParameter(valid_593854, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.AddTags"))
  if valid_593854 != nil:
    section.add "X-Amz-Target", valid_593854
  var valid_593855 = header.getOrDefault("X-Amz-Signature")
  valid_593855 = validateParameter(valid_593855, JString, required = false,
                                 default = nil)
  if valid_593855 != nil:
    section.add "X-Amz-Signature", valid_593855
  var valid_593856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593856 = validateParameter(valid_593856, JString, required = false,
                                 default = nil)
  if valid_593856 != nil:
    section.add "X-Amz-Content-Sha256", valid_593856
  var valid_593857 = header.getOrDefault("X-Amz-Date")
  valid_593857 = validateParameter(valid_593857, JString, required = false,
                                 default = nil)
  if valid_593857 != nil:
    section.add "X-Amz-Date", valid_593857
  var valid_593858 = header.getOrDefault("X-Amz-Credential")
  valid_593858 = validateParameter(valid_593858, JString, required = false,
                                 default = nil)
  if valid_593858 != nil:
    section.add "X-Amz-Credential", valid_593858
  var valid_593859 = header.getOrDefault("X-Amz-Security-Token")
  valid_593859 = validateParameter(valid_593859, JString, required = false,
                                 default = nil)
  if valid_593859 != nil:
    section.add "X-Amz-Security-Token", valid_593859
  var valid_593860 = header.getOrDefault("X-Amz-Algorithm")
  valid_593860 = validateParameter(valid_593860, JString, required = false,
                                 default = nil)
  if valid_593860 != nil:
    section.add "X-Amz-Algorithm", valid_593860
  var valid_593861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593861 = validateParameter(valid_593861, JString, required = false,
                                 default = nil)
  if valid_593861 != nil:
    section.add "X-Amz-SignedHeaders", valid_593861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593885: Call_AddTags_593727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to a trail, up to a limit of 50. Overwrites an existing tag's value when a new value is specified for an existing tag key. Tag key names must be unique for a trail; you cannot have two keys with the same name but different values. If you specify a key without a value, the tag will be created with the specified key and a value of null. You can tag a trail that applies to all AWS Regions only from the Region in which the trail was created (also known as its home region).
  ## 
  let valid = call_593885.validator(path, query, header, formData, body)
  let scheme = call_593885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593885.url(scheme.get, call_593885.host, call_593885.base,
                         call_593885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593885, url, valid)

proc call*(call_593956: Call_AddTags_593727; body: JsonNode): Recallable =
  ## addTags
  ## Adds one or more tags to a trail, up to a limit of 50. Overwrites an existing tag's value when a new value is specified for an existing tag key. Tag key names must be unique for a trail; you cannot have two keys with the same name but different values. If you specify a key without a value, the tag will be created with the specified key and a value of null. You can tag a trail that applies to all AWS Regions only from the Region in which the trail was created (also known as its home region).
  ##   body: JObject (required)
  var body_593957 = newJObject()
  if body != nil:
    body_593957 = body
  result = call_593956.call(nil, nil, nil, nil, body_593957)

var addTags* = Call_AddTags_593727(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.AddTags",
                                validator: validate_AddTags_593728, base: "/",
                                url: url_AddTags_593729,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrail_593996 = ref object of OpenApiRestCall_593389
proc url_CreateTrail_593998(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTrail_593997(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a trail that specifies the settings for delivery of log data to an Amazon S3 bucket. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593999 = header.getOrDefault("X-Amz-Target")
  valid_593999 = validateParameter(valid_593999, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.CreateTrail"))
  if valid_593999 != nil:
    section.add "X-Amz-Target", valid_593999
  var valid_594000 = header.getOrDefault("X-Amz-Signature")
  valid_594000 = validateParameter(valid_594000, JString, required = false,
                                 default = nil)
  if valid_594000 != nil:
    section.add "X-Amz-Signature", valid_594000
  var valid_594001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594001 = validateParameter(valid_594001, JString, required = false,
                                 default = nil)
  if valid_594001 != nil:
    section.add "X-Amz-Content-Sha256", valid_594001
  var valid_594002 = header.getOrDefault("X-Amz-Date")
  valid_594002 = validateParameter(valid_594002, JString, required = false,
                                 default = nil)
  if valid_594002 != nil:
    section.add "X-Amz-Date", valid_594002
  var valid_594003 = header.getOrDefault("X-Amz-Credential")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "X-Amz-Credential", valid_594003
  var valid_594004 = header.getOrDefault("X-Amz-Security-Token")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = nil)
  if valid_594004 != nil:
    section.add "X-Amz-Security-Token", valid_594004
  var valid_594005 = header.getOrDefault("X-Amz-Algorithm")
  valid_594005 = validateParameter(valid_594005, JString, required = false,
                                 default = nil)
  if valid_594005 != nil:
    section.add "X-Amz-Algorithm", valid_594005
  var valid_594006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594006 = validateParameter(valid_594006, JString, required = false,
                                 default = nil)
  if valid_594006 != nil:
    section.add "X-Amz-SignedHeaders", valid_594006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594008: Call_CreateTrail_593996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a trail that specifies the settings for delivery of log data to an Amazon S3 bucket. 
  ## 
  let valid = call_594008.validator(path, query, header, formData, body)
  let scheme = call_594008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594008.url(scheme.get, call_594008.host, call_594008.base,
                         call_594008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594008, url, valid)

proc call*(call_594009: Call_CreateTrail_593996; body: JsonNode): Recallable =
  ## createTrail
  ## Creates a trail that specifies the settings for delivery of log data to an Amazon S3 bucket. 
  ##   body: JObject (required)
  var body_594010 = newJObject()
  if body != nil:
    body_594010 = body
  result = call_594009.call(nil, nil, nil, nil, body_594010)

var createTrail* = Call_CreateTrail_593996(name: "createTrail",
                                        meth: HttpMethod.HttpPost,
                                        host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.CreateTrail",
                                        validator: validate_CreateTrail_593997,
                                        base: "/", url: url_CreateTrail_593998,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrail_594011 = ref object of OpenApiRestCall_593389
proc url_DeleteTrail_594013(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTrail_594012(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a trail. This operation must be called from the region in which the trail was created. <code>DeleteTrail</code> cannot be called on the shadow trails (replicated trails in other regions) of a trail that is enabled in all regions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594014 = header.getOrDefault("X-Amz-Target")
  valid_594014 = validateParameter(valid_594014, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DeleteTrail"))
  if valid_594014 != nil:
    section.add "X-Amz-Target", valid_594014
  var valid_594015 = header.getOrDefault("X-Amz-Signature")
  valid_594015 = validateParameter(valid_594015, JString, required = false,
                                 default = nil)
  if valid_594015 != nil:
    section.add "X-Amz-Signature", valid_594015
  var valid_594016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594016 = validateParameter(valid_594016, JString, required = false,
                                 default = nil)
  if valid_594016 != nil:
    section.add "X-Amz-Content-Sha256", valid_594016
  var valid_594017 = header.getOrDefault("X-Amz-Date")
  valid_594017 = validateParameter(valid_594017, JString, required = false,
                                 default = nil)
  if valid_594017 != nil:
    section.add "X-Amz-Date", valid_594017
  var valid_594018 = header.getOrDefault("X-Amz-Credential")
  valid_594018 = validateParameter(valid_594018, JString, required = false,
                                 default = nil)
  if valid_594018 != nil:
    section.add "X-Amz-Credential", valid_594018
  var valid_594019 = header.getOrDefault("X-Amz-Security-Token")
  valid_594019 = validateParameter(valid_594019, JString, required = false,
                                 default = nil)
  if valid_594019 != nil:
    section.add "X-Amz-Security-Token", valid_594019
  var valid_594020 = header.getOrDefault("X-Amz-Algorithm")
  valid_594020 = validateParameter(valid_594020, JString, required = false,
                                 default = nil)
  if valid_594020 != nil:
    section.add "X-Amz-Algorithm", valid_594020
  var valid_594021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594021 = validateParameter(valid_594021, JString, required = false,
                                 default = nil)
  if valid_594021 != nil:
    section.add "X-Amz-SignedHeaders", valid_594021
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594023: Call_DeleteTrail_594011; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a trail. This operation must be called from the region in which the trail was created. <code>DeleteTrail</code> cannot be called on the shadow trails (replicated trails in other regions) of a trail that is enabled in all regions.
  ## 
  let valid = call_594023.validator(path, query, header, formData, body)
  let scheme = call_594023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594023.url(scheme.get, call_594023.host, call_594023.base,
                         call_594023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594023, url, valid)

proc call*(call_594024: Call_DeleteTrail_594011; body: JsonNode): Recallable =
  ## deleteTrail
  ## Deletes a trail. This operation must be called from the region in which the trail was created. <code>DeleteTrail</code> cannot be called on the shadow trails (replicated trails in other regions) of a trail that is enabled in all regions.
  ##   body: JObject (required)
  var body_594025 = newJObject()
  if body != nil:
    body_594025 = body
  result = call_594024.call(nil, nil, nil, nil, body_594025)

var deleteTrail* = Call_DeleteTrail_594011(name: "deleteTrail",
                                        meth: HttpMethod.HttpPost,
                                        host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DeleteTrail",
                                        validator: validate_DeleteTrail_594012,
                                        base: "/", url: url_DeleteTrail_594013,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrails_594026 = ref object of OpenApiRestCall_593389
proc url_DescribeTrails_594028(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTrails_594027(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves settings for one or more trails associated with the current region for your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594029 = header.getOrDefault("X-Amz-Target")
  valid_594029 = validateParameter(valid_594029, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DescribeTrails"))
  if valid_594029 != nil:
    section.add "X-Amz-Target", valid_594029
  var valid_594030 = header.getOrDefault("X-Amz-Signature")
  valid_594030 = validateParameter(valid_594030, JString, required = false,
                                 default = nil)
  if valid_594030 != nil:
    section.add "X-Amz-Signature", valid_594030
  var valid_594031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594031 = validateParameter(valid_594031, JString, required = false,
                                 default = nil)
  if valid_594031 != nil:
    section.add "X-Amz-Content-Sha256", valid_594031
  var valid_594032 = header.getOrDefault("X-Amz-Date")
  valid_594032 = validateParameter(valid_594032, JString, required = false,
                                 default = nil)
  if valid_594032 != nil:
    section.add "X-Amz-Date", valid_594032
  var valid_594033 = header.getOrDefault("X-Amz-Credential")
  valid_594033 = validateParameter(valid_594033, JString, required = false,
                                 default = nil)
  if valid_594033 != nil:
    section.add "X-Amz-Credential", valid_594033
  var valid_594034 = header.getOrDefault("X-Amz-Security-Token")
  valid_594034 = validateParameter(valid_594034, JString, required = false,
                                 default = nil)
  if valid_594034 != nil:
    section.add "X-Amz-Security-Token", valid_594034
  var valid_594035 = header.getOrDefault("X-Amz-Algorithm")
  valid_594035 = validateParameter(valid_594035, JString, required = false,
                                 default = nil)
  if valid_594035 != nil:
    section.add "X-Amz-Algorithm", valid_594035
  var valid_594036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594036 = validateParameter(valid_594036, JString, required = false,
                                 default = nil)
  if valid_594036 != nil:
    section.add "X-Amz-SignedHeaders", valid_594036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594038: Call_DescribeTrails_594026; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves settings for one or more trails associated with the current region for your account.
  ## 
  let valid = call_594038.validator(path, query, header, formData, body)
  let scheme = call_594038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594038.url(scheme.get, call_594038.host, call_594038.base,
                         call_594038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594038, url, valid)

proc call*(call_594039: Call_DescribeTrails_594026; body: JsonNode): Recallable =
  ## describeTrails
  ## Retrieves settings for one or more trails associated with the current region for your account.
  ##   body: JObject (required)
  var body_594040 = newJObject()
  if body != nil:
    body_594040 = body
  result = call_594039.call(nil, nil, nil, nil, body_594040)

var describeTrails* = Call_DescribeTrails_594026(name: "describeTrails",
    meth: HttpMethod.HttpPost, host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DescribeTrails",
    validator: validate_DescribeTrails_594027, base: "/", url: url_DescribeTrails_594028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventSelectors_594041 = ref object of OpenApiRestCall_593389
proc url_GetEventSelectors_594043(protocol: Scheme; host: string; base: string;
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

proc validate_GetEventSelectors_594042(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Describes the settings for the event selectors that you configured for your trail. The information returned for your event selectors includes the following:</p> <ul> <li> <p>If your event selector includes read-only events, write-only events, or all events. This applies to both management events and data events.</p> </li> <li> <p>If your event selector includes management events.</p> </li> <li> <p>If your event selector includes data events, the Amazon S3 objects or AWS Lambda functions that you are logging for data events.</p> </li> </ul> <p>For more information, see <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-management-and-data-events-with-cloudtrail.html">Logging Data and Management Events for Trails </a> in the <i>AWS CloudTrail User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594044 = header.getOrDefault("X-Amz-Target")
  valid_594044 = validateParameter(valid_594044, JString, required = true, default = newJString("com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetEventSelectors"))
  if valid_594044 != nil:
    section.add "X-Amz-Target", valid_594044
  var valid_594045 = header.getOrDefault("X-Amz-Signature")
  valid_594045 = validateParameter(valid_594045, JString, required = false,
                                 default = nil)
  if valid_594045 != nil:
    section.add "X-Amz-Signature", valid_594045
  var valid_594046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Content-Sha256", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Date")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Date", valid_594047
  var valid_594048 = header.getOrDefault("X-Amz-Credential")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-Credential", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Security-Token")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Security-Token", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-SignedHeaders", valid_594051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594053: Call_GetEventSelectors_594041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the settings for the event selectors that you configured for your trail. The information returned for your event selectors includes the following:</p> <ul> <li> <p>If your event selector includes read-only events, write-only events, or all events. This applies to both management events and data events.</p> </li> <li> <p>If your event selector includes management events.</p> </li> <li> <p>If your event selector includes data events, the Amazon S3 objects or AWS Lambda functions that you are logging for data events.</p> </li> </ul> <p>For more information, see <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-management-and-data-events-with-cloudtrail.html">Logging Data and Management Events for Trails </a> in the <i>AWS CloudTrail User Guide</i>.</p>
  ## 
  let valid = call_594053.validator(path, query, header, formData, body)
  let scheme = call_594053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594053.url(scheme.get, call_594053.host, call_594053.base,
                         call_594053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594053, url, valid)

proc call*(call_594054: Call_GetEventSelectors_594041; body: JsonNode): Recallable =
  ## getEventSelectors
  ## <p>Describes the settings for the event selectors that you configured for your trail. The information returned for your event selectors includes the following:</p> <ul> <li> <p>If your event selector includes read-only events, write-only events, or all events. This applies to both management events and data events.</p> </li> <li> <p>If your event selector includes management events.</p> </li> <li> <p>If your event selector includes data events, the Amazon S3 objects or AWS Lambda functions that you are logging for data events.</p> </li> </ul> <p>For more information, see <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-management-and-data-events-with-cloudtrail.html">Logging Data and Management Events for Trails </a> in the <i>AWS CloudTrail User Guide</i>.</p>
  ##   body: JObject (required)
  var body_594055 = newJObject()
  if body != nil:
    body_594055 = body
  result = call_594054.call(nil, nil, nil, nil, body_594055)

var getEventSelectors* = Call_GetEventSelectors_594041(name: "getEventSelectors",
    meth: HttpMethod.HttpPost, host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetEventSelectors",
    validator: validate_GetEventSelectors_594042, base: "/",
    url: url_GetEventSelectors_594043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrail_594056 = ref object of OpenApiRestCall_593389
proc url_GetTrail_594058(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetTrail_594057(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns settings information for a specified trail.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594059 = header.getOrDefault("X-Amz-Target")
  valid_594059 = validateParameter(valid_594059, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetTrail"))
  if valid_594059 != nil:
    section.add "X-Amz-Target", valid_594059
  var valid_594060 = header.getOrDefault("X-Amz-Signature")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-Signature", valid_594060
  var valid_594061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Content-Sha256", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Date")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Date", valid_594062
  var valid_594063 = header.getOrDefault("X-Amz-Credential")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "X-Amz-Credential", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Security-Token")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Security-Token", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Algorithm")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Algorithm", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-SignedHeaders", valid_594066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594068: Call_GetTrail_594056; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns settings information for a specified trail.
  ## 
  let valid = call_594068.validator(path, query, header, formData, body)
  let scheme = call_594068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594068.url(scheme.get, call_594068.host, call_594068.base,
                         call_594068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594068, url, valid)

proc call*(call_594069: Call_GetTrail_594056; body: JsonNode): Recallable =
  ## getTrail
  ## Returns settings information for a specified trail.
  ##   body: JObject (required)
  var body_594070 = newJObject()
  if body != nil:
    body_594070 = body
  result = call_594069.call(nil, nil, nil, nil, body_594070)

var getTrail* = Call_GetTrail_594056(name: "getTrail", meth: HttpMethod.HttpPost,
                                  host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetTrail",
                                  validator: validate_GetTrail_594057, base: "/",
                                  url: url_GetTrail_594058,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrailStatus_594071 = ref object of OpenApiRestCall_593389
proc url_GetTrailStatus_594073(protocol: Scheme; host: string; base: string;
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

proc validate_GetTrailStatus_594072(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns a JSON-formatted list of information about the specified trail. Fields include information on delivery errors, Amazon SNS and Amazon S3 errors, and start and stop logging times for each trail. This operation returns trail status from a single region. To return trail status from all regions, you must call the operation on each region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594074 = header.getOrDefault("X-Amz-Target")
  valid_594074 = validateParameter(valid_594074, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetTrailStatus"))
  if valid_594074 != nil:
    section.add "X-Amz-Target", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-Signature")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Signature", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Content-Sha256", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Date")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Date", valid_594077
  var valid_594078 = header.getOrDefault("X-Amz-Credential")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Credential", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Security-Token")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Security-Token", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Algorithm")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Algorithm", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-SignedHeaders", valid_594081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594083: Call_GetTrailStatus_594071; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a JSON-formatted list of information about the specified trail. Fields include information on delivery errors, Amazon SNS and Amazon S3 errors, and start and stop logging times for each trail. This operation returns trail status from a single region. To return trail status from all regions, you must call the operation on each region.
  ## 
  let valid = call_594083.validator(path, query, header, formData, body)
  let scheme = call_594083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594083.url(scheme.get, call_594083.host, call_594083.base,
                         call_594083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594083, url, valid)

proc call*(call_594084: Call_GetTrailStatus_594071; body: JsonNode): Recallable =
  ## getTrailStatus
  ## Returns a JSON-formatted list of information about the specified trail. Fields include information on delivery errors, Amazon SNS and Amazon S3 errors, and start and stop logging times for each trail. This operation returns trail status from a single region. To return trail status from all regions, you must call the operation on each region.
  ##   body: JObject (required)
  var body_594085 = newJObject()
  if body != nil:
    body_594085 = body
  result = call_594084.call(nil, nil, nil, nil, body_594085)

var getTrailStatus* = Call_GetTrailStatus_594071(name: "getTrailStatus",
    meth: HttpMethod.HttpPost, host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetTrailStatus",
    validator: validate_GetTrailStatus_594072, base: "/", url: url_GetTrailStatus_594073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublicKeys_594086 = ref object of OpenApiRestCall_593389
proc url_ListPublicKeys_594088(protocol: Scheme; host: string; base: string;
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

proc validate_ListPublicKeys_594087(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns all public keys whose private keys were used to sign the digest files within the specified time range. The public key is needed to validate digest files that were signed with its corresponding private key.</p> <note> <p>CloudTrail uses different private/public key pairs per region. Each digest file is signed with a private key unique to its region. Therefore, when you validate a digest file from a particular region, you must look in the same region for its corresponding public key.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594089 = query.getOrDefault("NextToken")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "NextToken", valid_594089
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594090 = header.getOrDefault("X-Amz-Target")
  valid_594090 = validateParameter(valid_594090, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListPublicKeys"))
  if valid_594090 != nil:
    section.add "X-Amz-Target", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-Signature")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Signature", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Content-Sha256", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Date")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Date", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Credential")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Credential", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Security-Token")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Security-Token", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Algorithm")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Algorithm", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-SignedHeaders", valid_594097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594099: Call_ListPublicKeys_594086; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns all public keys whose private keys were used to sign the digest files within the specified time range. The public key is needed to validate digest files that were signed with its corresponding private key.</p> <note> <p>CloudTrail uses different private/public key pairs per region. Each digest file is signed with a private key unique to its region. Therefore, when you validate a digest file from a particular region, you must look in the same region for its corresponding public key.</p> </note>
  ## 
  let valid = call_594099.validator(path, query, header, formData, body)
  let scheme = call_594099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594099.url(scheme.get, call_594099.host, call_594099.base,
                         call_594099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594099, url, valid)

proc call*(call_594100: Call_ListPublicKeys_594086; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## listPublicKeys
  ## <p>Returns all public keys whose private keys were used to sign the digest files within the specified time range. The public key is needed to validate digest files that were signed with its corresponding private key.</p> <note> <p>CloudTrail uses different private/public key pairs per region. Each digest file is signed with a private key unique to its region. Therefore, when you validate a digest file from a particular region, you must look in the same region for its corresponding public key.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594101 = newJObject()
  var body_594102 = newJObject()
  add(query_594101, "NextToken", newJString(NextToken))
  if body != nil:
    body_594102 = body
  result = call_594100.call(nil, query_594101, nil, nil, body_594102)

var listPublicKeys* = Call_ListPublicKeys_594086(name: "listPublicKeys",
    meth: HttpMethod.HttpPost, host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListPublicKeys",
    validator: validate_ListPublicKeys_594087, base: "/", url: url_ListPublicKeys_594088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_594104 = ref object of OpenApiRestCall_593389
proc url_ListTags_594106(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTags_594105(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the tags for the trail in the current region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594107 = query.getOrDefault("NextToken")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "NextToken", valid_594107
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594108 = header.getOrDefault("X-Amz-Target")
  valid_594108 = validateParameter(valid_594108, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListTags"))
  if valid_594108 != nil:
    section.add "X-Amz-Target", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Signature")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Signature", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Content-Sha256", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Date")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Date", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Credential")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Credential", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Security-Token")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Security-Token", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Algorithm")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Algorithm", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-SignedHeaders", valid_594115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594117: Call_ListTags_594104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for the trail in the current region.
  ## 
  let valid = call_594117.validator(path, query, header, formData, body)
  let scheme = call_594117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594117.url(scheme.get, call_594117.host, call_594117.base,
                         call_594117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594117, url, valid)

proc call*(call_594118: Call_ListTags_594104; body: JsonNode; NextToken: string = ""): Recallable =
  ## listTags
  ## Lists the tags for the trail in the current region.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594119 = newJObject()
  var body_594120 = newJObject()
  add(query_594119, "NextToken", newJString(NextToken))
  if body != nil:
    body_594120 = body
  result = call_594118.call(nil, query_594119, nil, nil, body_594120)

var listTags* = Call_ListTags_594104(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListTags",
                                  validator: validate_ListTags_594105, base: "/",
                                  url: url_ListTags_594106,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrails_594121 = ref object of OpenApiRestCall_593389
proc url_ListTrails_594123(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTrails_594122(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists trails that are in the current account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_594124 = query.getOrDefault("NextToken")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "NextToken", valid_594124
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594125 = header.getOrDefault("X-Amz-Target")
  valid_594125 = validateParameter(valid_594125, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListTrails"))
  if valid_594125 != nil:
    section.add "X-Amz-Target", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Signature")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Signature", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Content-Sha256", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Date")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Date", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Credential")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Credential", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-Security-Token")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Security-Token", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-Algorithm")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Algorithm", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-SignedHeaders", valid_594132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594134: Call_ListTrails_594121; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists trails that are in the current account.
  ## 
  let valid = call_594134.validator(path, query, header, formData, body)
  let scheme = call_594134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594134.url(scheme.get, call_594134.host, call_594134.base,
                         call_594134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594134, url, valid)

proc call*(call_594135: Call_ListTrails_594121; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## listTrails
  ## Lists trails that are in the current account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594136 = newJObject()
  var body_594137 = newJObject()
  add(query_594136, "NextToken", newJString(NextToken))
  if body != nil:
    body_594137 = body
  result = call_594135.call(nil, query_594136, nil, nil, body_594137)

var listTrails* = Call_ListTrails_594121(name: "listTrails",
                                      meth: HttpMethod.HttpPost,
                                      host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListTrails",
                                      validator: validate_ListTrails_594122,
                                      base: "/", url: url_ListTrails_594123,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_LookupEvents_594138 = ref object of OpenApiRestCall_593389
proc url_LookupEvents_594140(protocol: Scheme; host: string; base: string;
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

proc validate_LookupEvents_594139(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Looks up <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-concepts.html#cloudtrail-concepts-management-events">management events</a> captured by CloudTrail. You can look up events that occurred in a region within the last 90 days. Lookup supports the following attributes:</p> <ul> <li> <p>AWS access key</p> </li> <li> <p>Event ID</p> </li> <li> <p>Event name</p> </li> <li> <p>Event source</p> </li> <li> <p>Read only</p> </li> <li> <p>Resource name</p> </li> <li> <p>Resource type</p> </li> <li> <p>User name</p> </li> </ul> <p>All attributes are optional. The default number of results returned is 50, with a maximum of 50 possible. The response includes a token that you can use to get the next page of results.</p> <important> <p>The rate of lookup requests is limited to one per second per account. If this limit is exceeded, a throttling error occurs.</p> <p>Events that occurred during the selected time range will not be available for lookup if CloudTrail logging was not enabled when the events occurred.</p> </important>
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
  section = newJObject()
  var valid_594141 = query.getOrDefault("MaxResults")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "MaxResults", valid_594141
  var valid_594142 = query.getOrDefault("NextToken")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "NextToken", valid_594142
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594143 = header.getOrDefault("X-Amz-Target")
  valid_594143 = validateParameter(valid_594143, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.LookupEvents"))
  if valid_594143 != nil:
    section.add "X-Amz-Target", valid_594143
  var valid_594144 = header.getOrDefault("X-Amz-Signature")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-Signature", valid_594144
  var valid_594145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-Content-Sha256", valid_594145
  var valid_594146 = header.getOrDefault("X-Amz-Date")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Date", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Credential")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Credential", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-Security-Token")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Security-Token", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Algorithm")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Algorithm", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-SignedHeaders", valid_594150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594152: Call_LookupEvents_594138; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Looks up <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-concepts.html#cloudtrail-concepts-management-events">management events</a> captured by CloudTrail. You can look up events that occurred in a region within the last 90 days. Lookup supports the following attributes:</p> <ul> <li> <p>AWS access key</p> </li> <li> <p>Event ID</p> </li> <li> <p>Event name</p> </li> <li> <p>Event source</p> </li> <li> <p>Read only</p> </li> <li> <p>Resource name</p> </li> <li> <p>Resource type</p> </li> <li> <p>User name</p> </li> </ul> <p>All attributes are optional. The default number of results returned is 50, with a maximum of 50 possible. The response includes a token that you can use to get the next page of results.</p> <important> <p>The rate of lookup requests is limited to one per second per account. If this limit is exceeded, a throttling error occurs.</p> <p>Events that occurred during the selected time range will not be available for lookup if CloudTrail logging was not enabled when the events occurred.</p> </important>
  ## 
  let valid = call_594152.validator(path, query, header, formData, body)
  let scheme = call_594152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594152.url(scheme.get, call_594152.host, call_594152.base,
                         call_594152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594152, url, valid)

proc call*(call_594153: Call_LookupEvents_594138; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## lookupEvents
  ## <p>Looks up <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-concepts.html#cloudtrail-concepts-management-events">management events</a> captured by CloudTrail. You can look up events that occurred in a region within the last 90 days. Lookup supports the following attributes:</p> <ul> <li> <p>AWS access key</p> </li> <li> <p>Event ID</p> </li> <li> <p>Event name</p> </li> <li> <p>Event source</p> </li> <li> <p>Read only</p> </li> <li> <p>Resource name</p> </li> <li> <p>Resource type</p> </li> <li> <p>User name</p> </li> </ul> <p>All attributes are optional. The default number of results returned is 50, with a maximum of 50 possible. The response includes a token that you can use to get the next page of results.</p> <important> <p>The rate of lookup requests is limited to one per second per account. If this limit is exceeded, a throttling error occurs.</p> <p>Events that occurred during the selected time range will not be available for lookup if CloudTrail logging was not enabled when the events occurred.</p> </important>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_594154 = newJObject()
  var body_594155 = newJObject()
  add(query_594154, "MaxResults", newJString(MaxResults))
  add(query_594154, "NextToken", newJString(NextToken))
  if body != nil:
    body_594155 = body
  result = call_594153.call(nil, query_594154, nil, nil, body_594155)

var lookupEvents* = Call_LookupEvents_594138(name: "lookupEvents",
    meth: HttpMethod.HttpPost, host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.LookupEvents",
    validator: validate_LookupEvents_594139, base: "/", url: url_LookupEvents_594140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventSelectors_594156 = ref object of OpenApiRestCall_593389
proc url_PutEventSelectors_594158(protocol: Scheme; host: string; base: string;
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

proc validate_PutEventSelectors_594157(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Configures an event selector for your trail. Use event selectors to further specify the management and data event settings for your trail. By default, trails created without specific event selectors will be configured to log all read and write management events, and no data events. </p> <p>When an event occurs in your account, CloudTrail evaluates the event selectors in all trails. For each trail, if the event matches any event selector, the trail processes and logs the event. If the event doesn't match any event selector, the trail doesn't log the event. </p> <p>Example</p> <ol> <li> <p>You create an event selector for a trail and specify that you want write-only events.</p> </li> <li> <p>The EC2 <code>GetConsoleOutput</code> and <code>RunInstances</code> API operations occur in your account.</p> </li> <li> <p>CloudTrail evaluates whether the events match your event selectors.</p> </li> <li> <p>The <code>RunInstances</code> is a write-only event and it matches your event selector. The trail logs the event.</p> </li> <li> <p>The <code>GetConsoleOutput</code> is a read-only event but it doesn't match your event selector. The trail doesn't log the event. </p> </li> </ol> <p>The <code>PutEventSelectors</code> operation must be called from the region in which the trail was created; otherwise, an <code>InvalidHomeRegionException</code> is thrown.</p> <p>You can configure up to five event selectors for each trail. For more information, see <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-management-and-data-events-with-cloudtrail.html">Logging Data and Management Events for Trails </a> and <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/WhatIsCloudTrail-Limits.html">Limits in AWS CloudTrail</a> in the <i>AWS CloudTrail User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594159 = header.getOrDefault("X-Amz-Target")
  valid_594159 = validateParameter(valid_594159, JString, required = true, default = newJString("com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.PutEventSelectors"))
  if valid_594159 != nil:
    section.add "X-Amz-Target", valid_594159
  var valid_594160 = header.getOrDefault("X-Amz-Signature")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "X-Amz-Signature", valid_594160
  var valid_594161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Content-Sha256", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-Date")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-Date", valid_594162
  var valid_594163 = header.getOrDefault("X-Amz-Credential")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Credential", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-Security-Token")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-Security-Token", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-Algorithm")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Algorithm", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-SignedHeaders", valid_594166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594168: Call_PutEventSelectors_594156; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures an event selector for your trail. Use event selectors to further specify the management and data event settings for your trail. By default, trails created without specific event selectors will be configured to log all read and write management events, and no data events. </p> <p>When an event occurs in your account, CloudTrail evaluates the event selectors in all trails. For each trail, if the event matches any event selector, the trail processes and logs the event. If the event doesn't match any event selector, the trail doesn't log the event. </p> <p>Example</p> <ol> <li> <p>You create an event selector for a trail and specify that you want write-only events.</p> </li> <li> <p>The EC2 <code>GetConsoleOutput</code> and <code>RunInstances</code> API operations occur in your account.</p> </li> <li> <p>CloudTrail evaluates whether the events match your event selectors.</p> </li> <li> <p>The <code>RunInstances</code> is a write-only event and it matches your event selector. The trail logs the event.</p> </li> <li> <p>The <code>GetConsoleOutput</code> is a read-only event but it doesn't match your event selector. The trail doesn't log the event. </p> </li> </ol> <p>The <code>PutEventSelectors</code> operation must be called from the region in which the trail was created; otherwise, an <code>InvalidHomeRegionException</code> is thrown.</p> <p>You can configure up to five event selectors for each trail. For more information, see <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-management-and-data-events-with-cloudtrail.html">Logging Data and Management Events for Trails </a> and <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/WhatIsCloudTrail-Limits.html">Limits in AWS CloudTrail</a> in the <i>AWS CloudTrail User Guide</i>.</p>
  ## 
  let valid = call_594168.validator(path, query, header, formData, body)
  let scheme = call_594168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594168.url(scheme.get, call_594168.host, call_594168.base,
                         call_594168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594168, url, valid)

proc call*(call_594169: Call_PutEventSelectors_594156; body: JsonNode): Recallable =
  ## putEventSelectors
  ## <p>Configures an event selector for your trail. Use event selectors to further specify the management and data event settings for your trail. By default, trails created without specific event selectors will be configured to log all read and write management events, and no data events. </p> <p>When an event occurs in your account, CloudTrail evaluates the event selectors in all trails. For each trail, if the event matches any event selector, the trail processes and logs the event. If the event doesn't match any event selector, the trail doesn't log the event. </p> <p>Example</p> <ol> <li> <p>You create an event selector for a trail and specify that you want write-only events.</p> </li> <li> <p>The EC2 <code>GetConsoleOutput</code> and <code>RunInstances</code> API operations occur in your account.</p> </li> <li> <p>CloudTrail evaluates whether the events match your event selectors.</p> </li> <li> <p>The <code>RunInstances</code> is a write-only event and it matches your event selector. The trail logs the event.</p> </li> <li> <p>The <code>GetConsoleOutput</code> is a read-only event but it doesn't match your event selector. The trail doesn't log the event. </p> </li> </ol> <p>The <code>PutEventSelectors</code> operation must be called from the region in which the trail was created; otherwise, an <code>InvalidHomeRegionException</code> is thrown.</p> <p>You can configure up to five event selectors for each trail. For more information, see <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-management-and-data-events-with-cloudtrail.html">Logging Data and Management Events for Trails </a> and <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/WhatIsCloudTrail-Limits.html">Limits in AWS CloudTrail</a> in the <i>AWS CloudTrail User Guide</i>.</p>
  ##   body: JObject (required)
  var body_594170 = newJObject()
  if body != nil:
    body_594170 = body
  result = call_594169.call(nil, nil, nil, nil, body_594170)

var putEventSelectors* = Call_PutEventSelectors_594156(name: "putEventSelectors",
    meth: HttpMethod.HttpPost, host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.PutEventSelectors",
    validator: validate_PutEventSelectors_594157, base: "/",
    url: url_PutEventSelectors_594158, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTags_594171 = ref object of OpenApiRestCall_593389
proc url_RemoveTags_594173(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_RemoveTags_594172(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the specified tags from a trail.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594174 = header.getOrDefault("X-Amz-Target")
  valid_594174 = validateParameter(valid_594174, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.RemoveTags"))
  if valid_594174 != nil:
    section.add "X-Amz-Target", valid_594174
  var valid_594175 = header.getOrDefault("X-Amz-Signature")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "X-Amz-Signature", valid_594175
  var valid_594176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "X-Amz-Content-Sha256", valid_594176
  var valid_594177 = header.getOrDefault("X-Amz-Date")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "X-Amz-Date", valid_594177
  var valid_594178 = header.getOrDefault("X-Amz-Credential")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "X-Amz-Credential", valid_594178
  var valid_594179 = header.getOrDefault("X-Amz-Security-Token")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "X-Amz-Security-Token", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-Algorithm")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Algorithm", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-SignedHeaders", valid_594181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594183: Call_RemoveTags_594171; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from a trail.
  ## 
  let valid = call_594183.validator(path, query, header, formData, body)
  let scheme = call_594183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594183.url(scheme.get, call_594183.host, call_594183.base,
                         call_594183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594183, url, valid)

proc call*(call_594184: Call_RemoveTags_594171; body: JsonNode): Recallable =
  ## removeTags
  ## Removes the specified tags from a trail.
  ##   body: JObject (required)
  var body_594185 = newJObject()
  if body != nil:
    body_594185 = body
  result = call_594184.call(nil, nil, nil, nil, body_594185)

var removeTags* = Call_RemoveTags_594171(name: "removeTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.RemoveTags",
                                      validator: validate_RemoveTags_594172,
                                      base: "/", url: url_RemoveTags_594173,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartLogging_594186 = ref object of OpenApiRestCall_593389
proc url_StartLogging_594188(protocol: Scheme; host: string; base: string;
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

proc validate_StartLogging_594187(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts the recording of AWS API calls and log file delivery for a trail. For a trail that is enabled in all regions, this operation must be called from the region in which the trail was created. This operation cannot be called on the shadow trails (replicated trails in other regions) of a trail that is enabled in all regions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594189 = header.getOrDefault("X-Amz-Target")
  valid_594189 = validateParameter(valid_594189, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.StartLogging"))
  if valid_594189 != nil:
    section.add "X-Amz-Target", valid_594189
  var valid_594190 = header.getOrDefault("X-Amz-Signature")
  valid_594190 = validateParameter(valid_594190, JString, required = false,
                                 default = nil)
  if valid_594190 != nil:
    section.add "X-Amz-Signature", valid_594190
  var valid_594191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "X-Amz-Content-Sha256", valid_594191
  var valid_594192 = header.getOrDefault("X-Amz-Date")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "X-Amz-Date", valid_594192
  var valid_594193 = header.getOrDefault("X-Amz-Credential")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-Credential", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-Security-Token")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-Security-Token", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-Algorithm")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Algorithm", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-SignedHeaders", valid_594196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594198: Call_StartLogging_594186; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the recording of AWS API calls and log file delivery for a trail. For a trail that is enabled in all regions, this operation must be called from the region in which the trail was created. This operation cannot be called on the shadow trails (replicated trails in other regions) of a trail that is enabled in all regions.
  ## 
  let valid = call_594198.validator(path, query, header, formData, body)
  let scheme = call_594198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594198.url(scheme.get, call_594198.host, call_594198.base,
                         call_594198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594198, url, valid)

proc call*(call_594199: Call_StartLogging_594186; body: JsonNode): Recallable =
  ## startLogging
  ## Starts the recording of AWS API calls and log file delivery for a trail. For a trail that is enabled in all regions, this operation must be called from the region in which the trail was created. This operation cannot be called on the shadow trails (replicated trails in other regions) of a trail that is enabled in all regions.
  ##   body: JObject (required)
  var body_594200 = newJObject()
  if body != nil:
    body_594200 = body
  result = call_594199.call(nil, nil, nil, nil, body_594200)

var startLogging* = Call_StartLogging_594186(name: "startLogging",
    meth: HttpMethod.HttpPost, host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.StartLogging",
    validator: validate_StartLogging_594187, base: "/", url: url_StartLogging_594188,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopLogging_594201 = ref object of OpenApiRestCall_593389
proc url_StopLogging_594203(protocol: Scheme; host: string; base: string;
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

proc validate_StopLogging_594202(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Suspends the recording of AWS API calls and log file delivery for the specified trail. Under most circumstances, there is no need to use this action. You can update a trail without stopping it first. This action is the only way to stop recording. For a trail enabled in all regions, this operation must be called from the region in which the trail was created, or an <code>InvalidHomeRegionException</code> will occur. This operation cannot be called on the shadow trails (replicated trails in other regions) of a trail enabled in all regions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594204 = header.getOrDefault("X-Amz-Target")
  valid_594204 = validateParameter(valid_594204, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.StopLogging"))
  if valid_594204 != nil:
    section.add "X-Amz-Target", valid_594204
  var valid_594205 = header.getOrDefault("X-Amz-Signature")
  valid_594205 = validateParameter(valid_594205, JString, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "X-Amz-Signature", valid_594205
  var valid_594206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "X-Amz-Content-Sha256", valid_594206
  var valid_594207 = header.getOrDefault("X-Amz-Date")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "X-Amz-Date", valid_594207
  var valid_594208 = header.getOrDefault("X-Amz-Credential")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "X-Amz-Credential", valid_594208
  var valid_594209 = header.getOrDefault("X-Amz-Security-Token")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Security-Token", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Algorithm")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Algorithm", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-SignedHeaders", valid_594211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594213: Call_StopLogging_594201; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Suspends the recording of AWS API calls and log file delivery for the specified trail. Under most circumstances, there is no need to use this action. You can update a trail without stopping it first. This action is the only way to stop recording. For a trail enabled in all regions, this operation must be called from the region in which the trail was created, or an <code>InvalidHomeRegionException</code> will occur. This operation cannot be called on the shadow trails (replicated trails in other regions) of a trail enabled in all regions.
  ## 
  let valid = call_594213.validator(path, query, header, formData, body)
  let scheme = call_594213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594213.url(scheme.get, call_594213.host, call_594213.base,
                         call_594213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594213, url, valid)

proc call*(call_594214: Call_StopLogging_594201; body: JsonNode): Recallable =
  ## stopLogging
  ## Suspends the recording of AWS API calls and log file delivery for the specified trail. Under most circumstances, there is no need to use this action. You can update a trail without stopping it first. This action is the only way to stop recording. For a trail enabled in all regions, this operation must be called from the region in which the trail was created, or an <code>InvalidHomeRegionException</code> will occur. This operation cannot be called on the shadow trails (replicated trails in other regions) of a trail enabled in all regions.
  ##   body: JObject (required)
  var body_594215 = newJObject()
  if body != nil:
    body_594215 = body
  result = call_594214.call(nil, nil, nil, nil, body_594215)

var stopLogging* = Call_StopLogging_594201(name: "stopLogging",
                                        meth: HttpMethod.HttpPost,
                                        host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.StopLogging",
                                        validator: validate_StopLogging_594202,
                                        base: "/", url: url_StopLogging_594203,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrail_594216 = ref object of OpenApiRestCall_593389
proc url_UpdateTrail_594218(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTrail_594217(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the settings that specify delivery of log files. Changes to a trail do not require stopping the CloudTrail service. Use this action to designate an existing bucket for log delivery. If the existing bucket has previously been a target for CloudTrail log files, an IAM policy exists for the bucket. <code>UpdateTrail</code> must be called from the region in which the trail was created; otherwise, an <code>InvalidHomeRegionException</code> is thrown.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594219 = header.getOrDefault("X-Amz-Target")
  valid_594219 = validateParameter(valid_594219, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.UpdateTrail"))
  if valid_594219 != nil:
    section.add "X-Amz-Target", valid_594219
  var valid_594220 = header.getOrDefault("X-Amz-Signature")
  valid_594220 = validateParameter(valid_594220, JString, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "X-Amz-Signature", valid_594220
  var valid_594221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "X-Amz-Content-Sha256", valid_594221
  var valid_594222 = header.getOrDefault("X-Amz-Date")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "X-Amz-Date", valid_594222
  var valid_594223 = header.getOrDefault("X-Amz-Credential")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "X-Amz-Credential", valid_594223
  var valid_594224 = header.getOrDefault("X-Amz-Security-Token")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "X-Amz-Security-Token", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Algorithm")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Algorithm", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-SignedHeaders", valid_594226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594228: Call_UpdateTrail_594216; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings that specify delivery of log files. Changes to a trail do not require stopping the CloudTrail service. Use this action to designate an existing bucket for log delivery. If the existing bucket has previously been a target for CloudTrail log files, an IAM policy exists for the bucket. <code>UpdateTrail</code> must be called from the region in which the trail was created; otherwise, an <code>InvalidHomeRegionException</code> is thrown.
  ## 
  let valid = call_594228.validator(path, query, header, formData, body)
  let scheme = call_594228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594228.url(scheme.get, call_594228.host, call_594228.base,
                         call_594228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594228, url, valid)

proc call*(call_594229: Call_UpdateTrail_594216; body: JsonNode): Recallable =
  ## updateTrail
  ## Updates the settings that specify delivery of log files. Changes to a trail do not require stopping the CloudTrail service. Use this action to designate an existing bucket for log delivery. If the existing bucket has previously been a target for CloudTrail log files, an IAM policy exists for the bucket. <code>UpdateTrail</code> must be called from the region in which the trail was created; otherwise, an <code>InvalidHomeRegionException</code> is thrown.
  ##   body: JObject (required)
  var body_594230 = newJObject()
  if body != nil:
    body_594230 = body
  result = call_594229.call(nil, nil, nil, nil, body_594230)

var updateTrail* = Call_UpdateTrail_594216(name: "updateTrail",
                                        meth: HttpMethod.HttpPost,
                                        host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.UpdateTrail",
                                        validator: validate_UpdateTrail_594217,
                                        base: "/", url: url_UpdateTrail_594218,
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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
