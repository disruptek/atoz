
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Translate
## version: 2017-07-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Provides translation between one source language and another of the same set of languages.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/translate/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "translate.ap-northeast-1.amazonaws.com", "ap-southeast-1": "translate.ap-southeast-1.amazonaws.com",
                           "us-west-2": "translate.us-west-2.amazonaws.com",
                           "eu-west-2": "translate.eu-west-2.amazonaws.com", "ap-northeast-3": "translate.ap-northeast-3.amazonaws.com", "eu-central-1": "translate.eu-central-1.amazonaws.com",
                           "us-east-2": "translate.us-east-2.amazonaws.com",
                           "us-east-1": "translate.us-east-1.amazonaws.com", "cn-northwest-1": "translate.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "translate.ap-south-1.amazonaws.com",
                           "eu-north-1": "translate.eu-north-1.amazonaws.com", "ap-northeast-2": "translate.ap-northeast-2.amazonaws.com",
                           "us-west-1": "translate.us-west-1.amazonaws.com", "us-gov-east-1": "translate.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "translate.eu-west-3.amazonaws.com", "cn-north-1": "translate.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "translate.sa-east-1.amazonaws.com",
                           "eu-west-1": "translate.eu-west-1.amazonaws.com", "us-gov-west-1": "translate.us-gov-west-1.amazonaws.com", "ap-southeast-2": "translate.ap-southeast-2.amazonaws.com", "ca-central-1": "translate.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "translate.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "translate.ap-southeast-1.amazonaws.com",
      "us-west-2": "translate.us-west-2.amazonaws.com",
      "eu-west-2": "translate.eu-west-2.amazonaws.com",
      "ap-northeast-3": "translate.ap-northeast-3.amazonaws.com",
      "eu-central-1": "translate.eu-central-1.amazonaws.com",
      "us-east-2": "translate.us-east-2.amazonaws.com",
      "us-east-1": "translate.us-east-1.amazonaws.com",
      "cn-northwest-1": "translate.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "translate.ap-south-1.amazonaws.com",
      "eu-north-1": "translate.eu-north-1.amazonaws.com",
      "ap-northeast-2": "translate.ap-northeast-2.amazonaws.com",
      "us-west-1": "translate.us-west-1.amazonaws.com",
      "us-gov-east-1": "translate.us-gov-east-1.amazonaws.com",
      "eu-west-3": "translate.eu-west-3.amazonaws.com",
      "cn-north-1": "translate.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "translate.sa-east-1.amazonaws.com",
      "eu-west-1": "translate.eu-west-1.amazonaws.com",
      "us-gov-west-1": "translate.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "translate.ap-southeast-2.amazonaws.com",
      "ca-central-1": "translate.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "translate"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_DeleteTerminology_610996 = ref object of OpenApiRestCall_610658
proc url_DeleteTerminology_610998(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTerminology_610997(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## A synchronous action that deletes a custom terminology.
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
  var valid_611123 = header.getOrDefault("X-Amz-Target")
  valid_611123 = validateParameter(valid_611123, JString, required = true, default = newJString(
      "AWSShineFrontendService_20170701.DeleteTerminology"))
  if valid_611123 != nil:
    section.add "X-Amz-Target", valid_611123
  var valid_611124 = header.getOrDefault("X-Amz-Signature")
  valid_611124 = validateParameter(valid_611124, JString, required = false,
                                 default = nil)
  if valid_611124 != nil:
    section.add "X-Amz-Signature", valid_611124
  var valid_611125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "X-Amz-Content-Sha256", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Date")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Date", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Credential")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Credential", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Security-Token")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Security-Token", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Algorithm")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Algorithm", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-SignedHeaders", valid_611130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611154: Call_DeleteTerminology_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A synchronous action that deletes a custom terminology.
  ## 
  let valid = call_611154.validator(path, query, header, formData, body)
  let scheme = call_611154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611154.url(scheme.get, call_611154.host, call_611154.base,
                         call_611154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611154, url, valid)

proc call*(call_611225: Call_DeleteTerminology_610996; body: JsonNode): Recallable =
  ## deleteTerminology
  ## A synchronous action that deletes a custom terminology.
  ##   body: JObject (required)
  var body_611226 = newJObject()
  if body != nil:
    body_611226 = body
  result = call_611225.call(nil, nil, nil, nil, body_611226)

var deleteTerminology* = Call_DeleteTerminology_610996(name: "deleteTerminology",
    meth: HttpMethod.HttpPost, host: "translate.amazonaws.com",
    route: "/#X-Amz-Target=AWSShineFrontendService_20170701.DeleteTerminology",
    validator: validate_DeleteTerminology_610997, base: "/",
    url: url_DeleteTerminology_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTextTranslationJob_611265 = ref object of OpenApiRestCall_610658
proc url_DescribeTextTranslationJob_611267(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTextTranslationJob_611266(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the properties associated with an asycnhronous batch translation job including name, ID, status, source and target languages, input/output S3 buckets, and so on.
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
  var valid_611268 = header.getOrDefault("X-Amz-Target")
  valid_611268 = validateParameter(valid_611268, JString, required = true, default = newJString(
      "AWSShineFrontendService_20170701.DescribeTextTranslationJob"))
  if valid_611268 != nil:
    section.add "X-Amz-Target", valid_611268
  var valid_611269 = header.getOrDefault("X-Amz-Signature")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Signature", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Content-Sha256", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Date")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Date", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Credential")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Credential", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Security-Token")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Security-Token", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Algorithm")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Algorithm", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-SignedHeaders", valid_611275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611277: Call_DescribeTextTranslationJob_611265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the properties associated with an asycnhronous batch translation job including name, ID, status, source and target languages, input/output S3 buckets, and so on.
  ## 
  let valid = call_611277.validator(path, query, header, formData, body)
  let scheme = call_611277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611277.url(scheme.get, call_611277.host, call_611277.base,
                         call_611277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611277, url, valid)

proc call*(call_611278: Call_DescribeTextTranslationJob_611265; body: JsonNode): Recallable =
  ## describeTextTranslationJob
  ## Gets the properties associated with an asycnhronous batch translation job including name, ID, status, source and target languages, input/output S3 buckets, and so on.
  ##   body: JObject (required)
  var body_611279 = newJObject()
  if body != nil:
    body_611279 = body
  result = call_611278.call(nil, nil, nil, nil, body_611279)

var describeTextTranslationJob* = Call_DescribeTextTranslationJob_611265(
    name: "describeTextTranslationJob", meth: HttpMethod.HttpPost,
    host: "translate.amazonaws.com", route: "/#X-Amz-Target=AWSShineFrontendService_20170701.DescribeTextTranslationJob",
    validator: validate_DescribeTextTranslationJob_611266, base: "/",
    url: url_DescribeTextTranslationJob_611267,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTerminology_611280 = ref object of OpenApiRestCall_610658
proc url_GetTerminology_611282(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTerminology_611281(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves a custom terminology.
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
  var valid_611283 = header.getOrDefault("X-Amz-Target")
  valid_611283 = validateParameter(valid_611283, JString, required = true, default = newJString(
      "AWSShineFrontendService_20170701.GetTerminology"))
  if valid_611283 != nil:
    section.add "X-Amz-Target", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-Signature")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Signature", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Content-Sha256", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Date")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Date", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Credential")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Credential", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Security-Token")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Security-Token", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Algorithm")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Algorithm", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-SignedHeaders", valid_611290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611292: Call_GetTerminology_611280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a custom terminology.
  ## 
  let valid = call_611292.validator(path, query, header, formData, body)
  let scheme = call_611292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611292.url(scheme.get, call_611292.host, call_611292.base,
                         call_611292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611292, url, valid)

proc call*(call_611293: Call_GetTerminology_611280; body: JsonNode): Recallable =
  ## getTerminology
  ## Retrieves a custom terminology.
  ##   body: JObject (required)
  var body_611294 = newJObject()
  if body != nil:
    body_611294 = body
  result = call_611293.call(nil, nil, nil, nil, body_611294)

var getTerminology* = Call_GetTerminology_611280(name: "getTerminology",
    meth: HttpMethod.HttpPost, host: "translate.amazonaws.com",
    route: "/#X-Amz-Target=AWSShineFrontendService_20170701.GetTerminology",
    validator: validate_GetTerminology_611281, base: "/", url: url_GetTerminology_611282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ImportTerminology_611295 = ref object of OpenApiRestCall_610658
proc url_ImportTerminology_611297(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ImportTerminology_611296(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates or updates a custom terminology, depending on whether or not one already exists for the given terminology name. Importing a terminology with the same name as an existing one will merge the terminologies based on the chosen merge strategy. Currently, the only supported merge strategy is OVERWRITE, and so the imported terminology will overwrite an existing terminology of the same name.</p> <p>If you import a terminology that overwrites an existing one, the new terminology take up to 10 minutes to fully propagate and be available for use in a translation due to cache policies with the DataPlane service that performs the translations.</p>
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
  var valid_611298 = header.getOrDefault("X-Amz-Target")
  valid_611298 = validateParameter(valid_611298, JString, required = true, default = newJString(
      "AWSShineFrontendService_20170701.ImportTerminology"))
  if valid_611298 != nil:
    section.add "X-Amz-Target", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Signature")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Signature", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Content-Sha256", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Date")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Date", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-Credential")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Credential", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Security-Token")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Security-Token", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Algorithm")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Algorithm", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-SignedHeaders", valid_611305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611307: Call_ImportTerminology_611295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates a custom terminology, depending on whether or not one already exists for the given terminology name. Importing a terminology with the same name as an existing one will merge the terminologies based on the chosen merge strategy. Currently, the only supported merge strategy is OVERWRITE, and so the imported terminology will overwrite an existing terminology of the same name.</p> <p>If you import a terminology that overwrites an existing one, the new terminology take up to 10 minutes to fully propagate and be available for use in a translation due to cache policies with the DataPlane service that performs the translations.</p>
  ## 
  let valid = call_611307.validator(path, query, header, formData, body)
  let scheme = call_611307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611307.url(scheme.get, call_611307.host, call_611307.base,
                         call_611307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611307, url, valid)

proc call*(call_611308: Call_ImportTerminology_611295; body: JsonNode): Recallable =
  ## importTerminology
  ## <p>Creates or updates a custom terminology, depending on whether or not one already exists for the given terminology name. Importing a terminology with the same name as an existing one will merge the terminologies based on the chosen merge strategy. Currently, the only supported merge strategy is OVERWRITE, and so the imported terminology will overwrite an existing terminology of the same name.</p> <p>If you import a terminology that overwrites an existing one, the new terminology take up to 10 minutes to fully propagate and be available for use in a translation due to cache policies with the DataPlane service that performs the translations.</p>
  ##   body: JObject (required)
  var body_611309 = newJObject()
  if body != nil:
    body_611309 = body
  result = call_611308.call(nil, nil, nil, nil, body_611309)

var importTerminology* = Call_ImportTerminology_611295(name: "importTerminology",
    meth: HttpMethod.HttpPost, host: "translate.amazonaws.com",
    route: "/#X-Amz-Target=AWSShineFrontendService_20170701.ImportTerminology",
    validator: validate_ImportTerminology_611296, base: "/",
    url: url_ImportTerminology_611297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTerminologies_611310 = ref object of OpenApiRestCall_610658
proc url_ListTerminologies_611312(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTerminologies_611311(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Provides a list of custom terminologies associated with your account.
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
  var valid_611313 = query.getOrDefault("MaxResults")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "MaxResults", valid_611313
  var valid_611314 = query.getOrDefault("NextToken")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "NextToken", valid_611314
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
  var valid_611315 = header.getOrDefault("X-Amz-Target")
  valid_611315 = validateParameter(valid_611315, JString, required = true, default = newJString(
      "AWSShineFrontendService_20170701.ListTerminologies"))
  if valid_611315 != nil:
    section.add "X-Amz-Target", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Signature")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Signature", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Content-Sha256", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Date")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Date", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Credential")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Credential", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-Security-Token")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-Security-Token", valid_611320
  var valid_611321 = header.getOrDefault("X-Amz-Algorithm")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-Algorithm", valid_611321
  var valid_611322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-SignedHeaders", valid_611322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611324: Call_ListTerminologies_611310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of custom terminologies associated with your account.
  ## 
  let valid = call_611324.validator(path, query, header, formData, body)
  let scheme = call_611324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611324.url(scheme.get, call_611324.host, call_611324.base,
                         call_611324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611324, url, valid)

proc call*(call_611325: Call_ListTerminologies_611310; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTerminologies
  ## Provides a list of custom terminologies associated with your account.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611326 = newJObject()
  var body_611327 = newJObject()
  add(query_611326, "MaxResults", newJString(MaxResults))
  add(query_611326, "NextToken", newJString(NextToken))
  if body != nil:
    body_611327 = body
  result = call_611325.call(nil, query_611326, nil, nil, body_611327)

var listTerminologies* = Call_ListTerminologies_611310(name: "listTerminologies",
    meth: HttpMethod.HttpPost, host: "translate.amazonaws.com",
    route: "/#X-Amz-Target=AWSShineFrontendService_20170701.ListTerminologies",
    validator: validate_ListTerminologies_611311, base: "/",
    url: url_ListTerminologies_611312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTextTranslationJobs_611329 = ref object of OpenApiRestCall_610658
proc url_ListTextTranslationJobs_611331(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTextTranslationJobs_611330(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets a list of the batch translation jobs that you have submitted.
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
  var valid_611332 = query.getOrDefault("MaxResults")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "MaxResults", valid_611332
  var valid_611333 = query.getOrDefault("NextToken")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "NextToken", valid_611333
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
  var valid_611334 = header.getOrDefault("X-Amz-Target")
  valid_611334 = validateParameter(valid_611334, JString, required = true, default = newJString(
      "AWSShineFrontendService_20170701.ListTextTranslationJobs"))
  if valid_611334 != nil:
    section.add "X-Amz-Target", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-Signature")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-Signature", valid_611335
  var valid_611336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-Content-Sha256", valid_611336
  var valid_611337 = header.getOrDefault("X-Amz-Date")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Date", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-Credential")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Credential", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-Security-Token")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Security-Token", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Algorithm")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Algorithm", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-SignedHeaders", valid_611341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611343: Call_ListTextTranslationJobs_611329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets a list of the batch translation jobs that you have submitted.
  ## 
  let valid = call_611343.validator(path, query, header, formData, body)
  let scheme = call_611343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611343.url(scheme.get, call_611343.host, call_611343.base,
                         call_611343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611343, url, valid)

proc call*(call_611344: Call_ListTextTranslationJobs_611329; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listTextTranslationJobs
  ## Gets a list of the batch translation jobs that you have submitted.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_611345 = newJObject()
  var body_611346 = newJObject()
  add(query_611345, "MaxResults", newJString(MaxResults))
  add(query_611345, "NextToken", newJString(NextToken))
  if body != nil:
    body_611346 = body
  result = call_611344.call(nil, query_611345, nil, nil, body_611346)

var listTextTranslationJobs* = Call_ListTextTranslationJobs_611329(
    name: "listTextTranslationJobs", meth: HttpMethod.HttpPost,
    host: "translate.amazonaws.com", route: "/#X-Amz-Target=AWSShineFrontendService_20170701.ListTextTranslationJobs",
    validator: validate_ListTextTranslationJobs_611330, base: "/",
    url: url_ListTextTranslationJobs_611331, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartTextTranslationJob_611347 = ref object of OpenApiRestCall_610658
proc url_StartTextTranslationJob_611349(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartTextTranslationJob_611348(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts an asynchronous batch translation job. Batch translation jobs can be used to translate large volumes of text across multiple documents at once. For more information, see <a>async</a>.</p> <p>Batch translation jobs can be described with the <a>DescribeTextTranslationJob</a> operation, listed with the <a>ListTextTranslationJobs</a> operation, and stopped with the <a>StopTextTranslationJob</a> operation.</p> <note> <p>Amazon Translate does not support batch translation of multiple source languages at once.</p> </note>
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
  var valid_611350 = header.getOrDefault("X-Amz-Target")
  valid_611350 = validateParameter(valid_611350, JString, required = true, default = newJString(
      "AWSShineFrontendService_20170701.StartTextTranslationJob"))
  if valid_611350 != nil:
    section.add "X-Amz-Target", valid_611350
  var valid_611351 = header.getOrDefault("X-Amz-Signature")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-Signature", valid_611351
  var valid_611352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Content-Sha256", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-Date")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Date", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-Credential")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Credential", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Security-Token")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Security-Token", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-Algorithm")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Algorithm", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-SignedHeaders", valid_611357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611359: Call_StartTextTranslationJob_611347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts an asynchronous batch translation job. Batch translation jobs can be used to translate large volumes of text across multiple documents at once. For more information, see <a>async</a>.</p> <p>Batch translation jobs can be described with the <a>DescribeTextTranslationJob</a> operation, listed with the <a>ListTextTranslationJobs</a> operation, and stopped with the <a>StopTextTranslationJob</a> operation.</p> <note> <p>Amazon Translate does not support batch translation of multiple source languages at once.</p> </note>
  ## 
  let valid = call_611359.validator(path, query, header, formData, body)
  let scheme = call_611359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611359.url(scheme.get, call_611359.host, call_611359.base,
                         call_611359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611359, url, valid)

proc call*(call_611360: Call_StartTextTranslationJob_611347; body: JsonNode): Recallable =
  ## startTextTranslationJob
  ## <p>Starts an asynchronous batch translation job. Batch translation jobs can be used to translate large volumes of text across multiple documents at once. For more information, see <a>async</a>.</p> <p>Batch translation jobs can be described with the <a>DescribeTextTranslationJob</a> operation, listed with the <a>ListTextTranslationJobs</a> operation, and stopped with the <a>StopTextTranslationJob</a> operation.</p> <note> <p>Amazon Translate does not support batch translation of multiple source languages at once.</p> </note>
  ##   body: JObject (required)
  var body_611361 = newJObject()
  if body != nil:
    body_611361 = body
  result = call_611360.call(nil, nil, nil, nil, body_611361)

var startTextTranslationJob* = Call_StartTextTranslationJob_611347(
    name: "startTextTranslationJob", meth: HttpMethod.HttpPost,
    host: "translate.amazonaws.com", route: "/#X-Amz-Target=AWSShineFrontendService_20170701.StartTextTranslationJob",
    validator: validate_StartTextTranslationJob_611348, base: "/",
    url: url_StartTextTranslationJob_611349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopTextTranslationJob_611362 = ref object of OpenApiRestCall_610658
proc url_StopTextTranslationJob_611364(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopTextTranslationJob_611363(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Stops an asynchronous batch translation job that is in progress.</p> <p>If the job's state is <code>IN_PROGRESS</code>, the job will be marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state. Otherwise, the job is put into the <code>STOPPED</code> state.</p> <p>Asynchronous batch translation jobs are started with the <a>StartTextTranslationJob</a> operation. You can use the <a>DescribeTextTranslationJob</a> or <a>ListTextTranslationJobs</a> operations to get a batch translation job's <code>JobId</code>.</p>
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
  var valid_611365 = header.getOrDefault("X-Amz-Target")
  valid_611365 = validateParameter(valid_611365, JString, required = true, default = newJString(
      "AWSShineFrontendService_20170701.StopTextTranslationJob"))
  if valid_611365 != nil:
    section.add "X-Amz-Target", valid_611365
  var valid_611366 = header.getOrDefault("X-Amz-Signature")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "X-Amz-Signature", valid_611366
  var valid_611367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Content-Sha256", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-Date")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Date", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-Credential")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Credential", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-Security-Token")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Security-Token", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-Algorithm")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Algorithm", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-SignedHeaders", valid_611372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611374: Call_StopTextTranslationJob_611362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Stops an asynchronous batch translation job that is in progress.</p> <p>If the job's state is <code>IN_PROGRESS</code>, the job will be marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state. Otherwise, the job is put into the <code>STOPPED</code> state.</p> <p>Asynchronous batch translation jobs are started with the <a>StartTextTranslationJob</a> operation. You can use the <a>DescribeTextTranslationJob</a> or <a>ListTextTranslationJobs</a> operations to get a batch translation job's <code>JobId</code>.</p>
  ## 
  let valid = call_611374.validator(path, query, header, formData, body)
  let scheme = call_611374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611374.url(scheme.get, call_611374.host, call_611374.base,
                         call_611374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611374, url, valid)

proc call*(call_611375: Call_StopTextTranslationJob_611362; body: JsonNode): Recallable =
  ## stopTextTranslationJob
  ## <p>Stops an asynchronous batch translation job that is in progress.</p> <p>If the job's state is <code>IN_PROGRESS</code>, the job will be marked for termination and put into the <code>STOP_REQUESTED</code> state. If the job completes before it can be stopped, it is put into the <code>COMPLETED</code> state. Otherwise, the job is put into the <code>STOPPED</code> state.</p> <p>Asynchronous batch translation jobs are started with the <a>StartTextTranslationJob</a> operation. You can use the <a>DescribeTextTranslationJob</a> or <a>ListTextTranslationJobs</a> operations to get a batch translation job's <code>JobId</code>.</p>
  ##   body: JObject (required)
  var body_611376 = newJObject()
  if body != nil:
    body_611376 = body
  result = call_611375.call(nil, nil, nil, nil, body_611376)

var stopTextTranslationJob* = Call_StopTextTranslationJob_611362(
    name: "stopTextTranslationJob", meth: HttpMethod.HttpPost,
    host: "translate.amazonaws.com", route: "/#X-Amz-Target=AWSShineFrontendService_20170701.StopTextTranslationJob",
    validator: validate_StopTextTranslationJob_611363, base: "/",
    url: url_StopTextTranslationJob_611364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TranslateText_611377 = ref object of OpenApiRestCall_610658
proc url_TranslateText_611379(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TranslateText_611378(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Translates input text from the source language to the target language. For a list of available languages and language codes, see <a>what-is-languages</a>.
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
  var valid_611380 = header.getOrDefault("X-Amz-Target")
  valid_611380 = validateParameter(valid_611380, JString, required = true, default = newJString(
      "AWSShineFrontendService_20170701.TranslateText"))
  if valid_611380 != nil:
    section.add "X-Amz-Target", valid_611380
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

proc call*(call_611389: Call_TranslateText_611377; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Translates input text from the source language to the target language. For a list of available languages and language codes, see <a>what-is-languages</a>.
  ## 
  let valid = call_611389.validator(path, query, header, formData, body)
  let scheme = call_611389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611389.url(scheme.get, call_611389.host, call_611389.base,
                         call_611389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611389, url, valid)

proc call*(call_611390: Call_TranslateText_611377; body: JsonNode): Recallable =
  ## translateText
  ## Translates input text from the source language to the target language. For a list of available languages and language codes, see <a>what-is-languages</a>.
  ##   body: JObject (required)
  var body_611391 = newJObject()
  if body != nil:
    body_611391 = body
  result = call_611390.call(nil, nil, nil, nil, body_611391)

var translateText* = Call_TranslateText_611377(name: "translateText",
    meth: HttpMethod.HttpPost, host: "translate.amazonaws.com",
    route: "/#X-Amz-Target=AWSShineFrontendService_20170701.TranslateText",
    validator: validate_TranslateText_611378, base: "/", url: url_TranslateText_611379,
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
