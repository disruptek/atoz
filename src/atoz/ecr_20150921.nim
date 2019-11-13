
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon EC2 Container Registry
## version: 2015-09-21
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Elastic Container Registry</fullname> <p>Amazon Elastic Container Registry (Amazon ECR) is a managed Docker registry service. Customers can use the familiar Docker CLI to push, pull, and manage images. Amazon ECR provides a secure, scalable, and reliable registry. Amazon ECR supports private Docker repositories with resource-based permissions using IAM so that specific users or Amazon EC2 instances can access repositories and images. Developers can use the Docker CLI to author and manage images.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/ecr/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "api.ecr.ap-northeast-1.amazonaws.com", "ap-southeast-1": "api.ecr.ap-southeast-1.amazonaws.com",
                           "us-west-2": "api.ecr.us-west-2.amazonaws.com",
                           "eu-west-2": "api.ecr.eu-west-2.amazonaws.com", "ap-northeast-3": "api.ecr.ap-northeast-3.amazonaws.com", "eu-central-1": "api.ecr.eu-central-1.amazonaws.com",
                           "us-east-2": "api.ecr.us-east-2.amazonaws.com",
                           "us-east-1": "api.ecr.us-east-1.amazonaws.com", "cn-northwest-1": "api.ecr.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "api.ecr.ap-south-1.amazonaws.com",
                           "eu-north-1": "api.ecr.eu-north-1.amazonaws.com", "ap-northeast-2": "api.ecr.ap-northeast-2.amazonaws.com",
                           "us-west-1": "api.ecr.us-west-1.amazonaws.com", "us-gov-east-1": "api.ecr.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "api.ecr.eu-west-3.amazonaws.com",
                           "cn-north-1": "api.ecr.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "api.ecr.sa-east-1.amazonaws.com",
                           "eu-west-1": "api.ecr.eu-west-1.amazonaws.com", "us-gov-west-1": "api.ecr.us-gov-west-1.amazonaws.com", "ap-southeast-2": "api.ecr.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "api.ecr.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "api.ecr.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "api.ecr.ap-southeast-1.amazonaws.com",
      "us-west-2": "api.ecr.us-west-2.amazonaws.com",
      "eu-west-2": "api.ecr.eu-west-2.amazonaws.com",
      "ap-northeast-3": "api.ecr.ap-northeast-3.amazonaws.com",
      "eu-central-1": "api.ecr.eu-central-1.amazonaws.com",
      "us-east-2": "api.ecr.us-east-2.amazonaws.com",
      "us-east-1": "api.ecr.us-east-1.amazonaws.com",
      "cn-northwest-1": "api.ecr.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "api.ecr.ap-south-1.amazonaws.com",
      "eu-north-1": "api.ecr.eu-north-1.amazonaws.com",
      "ap-northeast-2": "api.ecr.ap-northeast-2.amazonaws.com",
      "us-west-1": "api.ecr.us-west-1.amazonaws.com",
      "us-gov-east-1": "api.ecr.us-gov-east-1.amazonaws.com",
      "eu-west-3": "api.ecr.eu-west-3.amazonaws.com",
      "cn-north-1": "api.ecr.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "api.ecr.sa-east-1.amazonaws.com",
      "eu-west-1": "api.ecr.eu-west-1.amazonaws.com",
      "us-gov-west-1": "api.ecr.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "api.ecr.ap-southeast-2.amazonaws.com",
      "ca-central-1": "api.ecr.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "ecr"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchCheckLayerAvailability_593727 = ref object of OpenApiRestCall_593389
proc url_BatchCheckLayerAvailability_593729(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchCheckLayerAvailability_593728(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Check the availability of multiple image layers in a specified registry and repository.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
      "AmazonEC2ContainerRegistry_V20150921.BatchCheckLayerAvailability"))
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

proc call*(call_593885: Call_BatchCheckLayerAvailability_593727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Check the availability of multiple image layers in a specified registry and repository.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_593885.validator(path, query, header, formData, body)
  let scheme = call_593885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593885.url(scheme.get, call_593885.host, call_593885.base,
                         call_593885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593885, url, valid)

proc call*(call_593956: Call_BatchCheckLayerAvailability_593727; body: JsonNode): Recallable =
  ## batchCheckLayerAvailability
  ## <p>Check the availability of multiple image layers in a specified registry and repository.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_593957 = newJObject()
  if body != nil:
    body_593957 = body
  result = call_593956.call(nil, nil, nil, nil, body_593957)

var batchCheckLayerAvailability* = Call_BatchCheckLayerAvailability_593727(
    name: "batchCheckLayerAvailability", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.BatchCheckLayerAvailability",
    validator: validate_BatchCheckLayerAvailability_593728, base: "/",
    url: url_BatchCheckLayerAvailability_593729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchDeleteImage_593996 = ref object of OpenApiRestCall_593389
proc url_BatchDeleteImage_593998(protocol: Scheme; host: string; base: string;
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

proc validate_BatchDeleteImage_593997(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes a list of specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.</p> <p>You can remove a tag from an image by specifying the image's tag in your request. When you remove the last tag from an image, the image is deleted from your repository.</p> <p>You can completely delete an image (and all of its tags) by specifying the image's digest in your request.</p>
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
      "AmazonEC2ContainerRegistry_V20150921.BatchDeleteImage"))
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

proc call*(call_594008: Call_BatchDeleteImage_593996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a list of specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.</p> <p>You can remove a tag from an image by specifying the image's tag in your request. When you remove the last tag from an image, the image is deleted from your repository.</p> <p>You can completely delete an image (and all of its tags) by specifying the image's digest in your request.</p>
  ## 
  let valid = call_594008.validator(path, query, header, formData, body)
  let scheme = call_594008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594008.url(scheme.get, call_594008.host, call_594008.base,
                         call_594008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594008, url, valid)

proc call*(call_594009: Call_BatchDeleteImage_593996; body: JsonNode): Recallable =
  ## batchDeleteImage
  ## <p>Deletes a list of specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.</p> <p>You can remove a tag from an image by specifying the image's tag in your request. When you remove the last tag from an image, the image is deleted from your repository.</p> <p>You can completely delete an image (and all of its tags) by specifying the image's digest in your request.</p>
  ##   body: JObject (required)
  var body_594010 = newJObject()
  if body != nil:
    body_594010 = body
  result = call_594009.call(nil, nil, nil, nil, body_594010)

var batchDeleteImage* = Call_BatchDeleteImage_593996(name: "batchDeleteImage",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.BatchDeleteImage",
    validator: validate_BatchDeleteImage_593997, base: "/",
    url: url_BatchDeleteImage_593998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetImage_594011 = ref object of OpenApiRestCall_593389
proc url_BatchGetImage_594013(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetImage_594012(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets detailed information for specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.
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
      "AmazonEC2ContainerRegistry_V20150921.BatchGetImage"))
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

proc call*(call_594023: Call_BatchGetImage_594011; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets detailed information for specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.
  ## 
  let valid = call_594023.validator(path, query, header, formData, body)
  let scheme = call_594023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594023.url(scheme.get, call_594023.host, call_594023.base,
                         call_594023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594023, url, valid)

proc call*(call_594024: Call_BatchGetImage_594011; body: JsonNode): Recallable =
  ## batchGetImage
  ## Gets detailed information for specified images within a specified repository. Images are specified with either <code>imageTag</code> or <code>imageDigest</code>.
  ##   body: JObject (required)
  var body_594025 = newJObject()
  if body != nil:
    body_594025 = body
  result = call_594024.call(nil, nil, nil, nil, body_594025)

var batchGetImage* = Call_BatchGetImage_594011(name: "batchGetImage",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.BatchGetImage",
    validator: validate_BatchGetImage_594012, base: "/", url: url_BatchGetImage_594013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CompleteLayerUpload_594026 = ref object of OpenApiRestCall_593389
proc url_CompleteLayerUpload_594028(protocol: Scheme; host: string; base: string;
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

proc validate_CompleteLayerUpload_594027(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Informs Amazon ECR that the image layer upload has completed for a specified registry, repository name, and upload ID. You can optionally provide a <code>sha256</code> digest of the image layer for data validation purposes.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
      "AmazonEC2ContainerRegistry_V20150921.CompleteLayerUpload"))
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

proc call*(call_594038: Call_CompleteLayerUpload_594026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Informs Amazon ECR that the image layer upload has completed for a specified registry, repository name, and upload ID. You can optionally provide a <code>sha256</code> digest of the image layer for data validation purposes.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_594038.validator(path, query, header, formData, body)
  let scheme = call_594038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594038.url(scheme.get, call_594038.host, call_594038.base,
                         call_594038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594038, url, valid)

proc call*(call_594039: Call_CompleteLayerUpload_594026; body: JsonNode): Recallable =
  ## completeLayerUpload
  ## <p>Informs Amazon ECR that the image layer upload has completed for a specified registry, repository name, and upload ID. You can optionally provide a <code>sha256</code> digest of the image layer for data validation purposes.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_594040 = newJObject()
  if body != nil:
    body_594040 = body
  result = call_594039.call(nil, nil, nil, nil, body_594040)

var completeLayerUpload* = Call_CompleteLayerUpload_594026(
    name: "completeLayerUpload", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.CompleteLayerUpload",
    validator: validate_CompleteLayerUpload_594027, base: "/",
    url: url_CompleteLayerUpload_594028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRepository_594041 = ref object of OpenApiRestCall_593389
proc url_CreateRepository_594043(protocol: Scheme; host: string; base: string;
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

proc validate_CreateRepository_594042(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates an Amazon Elastic Container Registry (Amazon ECR) repository, where users can push and pull Docker images. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/Repositories.html">Amazon ECR Repositories</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
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
  valid_594044 = validateParameter(valid_594044, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.CreateRepository"))
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

proc call*(call_594053: Call_CreateRepository_594041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon Elastic Container Registry (Amazon ECR) repository, where users can push and pull Docker images. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/Repositories.html">Amazon ECR Repositories</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ## 
  let valid = call_594053.validator(path, query, header, formData, body)
  let scheme = call_594053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594053.url(scheme.get, call_594053.host, call_594053.base,
                         call_594053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594053, url, valid)

proc call*(call_594054: Call_CreateRepository_594041; body: JsonNode): Recallable =
  ## createRepository
  ## Creates an Amazon Elastic Container Registry (Amazon ECR) repository, where users can push and pull Docker images. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/Repositories.html">Amazon ECR Repositories</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ##   body: JObject (required)
  var body_594055 = newJObject()
  if body != nil:
    body_594055 = body
  result = call_594054.call(nil, nil, nil, nil, body_594055)

var createRepository* = Call_CreateRepository_594041(name: "createRepository",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.CreateRepository",
    validator: validate_CreateRepository_594042, base: "/",
    url: url_CreateRepository_594043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLifecyclePolicy_594056 = ref object of OpenApiRestCall_593389
proc url_DeleteLifecyclePolicy_594058(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLifecyclePolicy_594057(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified lifecycle policy.
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
      "AmazonEC2ContainerRegistry_V20150921.DeleteLifecyclePolicy"))
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

proc call*(call_594068: Call_DeleteLifecyclePolicy_594056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified lifecycle policy.
  ## 
  let valid = call_594068.validator(path, query, header, formData, body)
  let scheme = call_594068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594068.url(scheme.get, call_594068.host, call_594068.base,
                         call_594068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594068, url, valid)

proc call*(call_594069: Call_DeleteLifecyclePolicy_594056; body: JsonNode): Recallable =
  ## deleteLifecyclePolicy
  ## Deletes the specified lifecycle policy.
  ##   body: JObject (required)
  var body_594070 = newJObject()
  if body != nil:
    body_594070 = body
  result = call_594069.call(nil, nil, nil, nil, body_594070)

var deleteLifecyclePolicy* = Call_DeleteLifecyclePolicy_594056(
    name: "deleteLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DeleteLifecyclePolicy",
    validator: validate_DeleteLifecyclePolicy_594057, base: "/",
    url: url_DeleteLifecyclePolicy_594058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRepository_594071 = ref object of OpenApiRestCall_593389
proc url_DeleteRepository_594073(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRepository_594072(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes an existing image repository. If a repository contains images, you must use the <code>force</code> option to delete it.
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
      "AmazonEC2ContainerRegistry_V20150921.DeleteRepository"))
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

proc call*(call_594083: Call_DeleteRepository_594071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing image repository. If a repository contains images, you must use the <code>force</code> option to delete it.
  ## 
  let valid = call_594083.validator(path, query, header, formData, body)
  let scheme = call_594083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594083.url(scheme.get, call_594083.host, call_594083.base,
                         call_594083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594083, url, valid)

proc call*(call_594084: Call_DeleteRepository_594071; body: JsonNode): Recallable =
  ## deleteRepository
  ## Deletes an existing image repository. If a repository contains images, you must use the <code>force</code> option to delete it.
  ##   body: JObject (required)
  var body_594085 = newJObject()
  if body != nil:
    body_594085 = body
  result = call_594084.call(nil, nil, nil, nil, body_594085)

var deleteRepository* = Call_DeleteRepository_594071(name: "deleteRepository",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DeleteRepository",
    validator: validate_DeleteRepository_594072, base: "/",
    url: url_DeleteRepository_594073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRepositoryPolicy_594086 = ref object of OpenApiRestCall_593389
proc url_DeleteRepositoryPolicy_594088(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteRepositoryPolicy_594087(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the repository policy from a specified repository.
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
  var valid_594089 = header.getOrDefault("X-Amz-Target")
  valid_594089 = validateParameter(valid_594089, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DeleteRepositoryPolicy"))
  if valid_594089 != nil:
    section.add "X-Amz-Target", valid_594089
  var valid_594090 = header.getOrDefault("X-Amz-Signature")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-Signature", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Content-Sha256", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Date")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Date", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Credential")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Credential", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Security-Token")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Security-Token", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Algorithm")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Algorithm", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-SignedHeaders", valid_594096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594098: Call_DeleteRepositoryPolicy_594086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the repository policy from a specified repository.
  ## 
  let valid = call_594098.validator(path, query, header, formData, body)
  let scheme = call_594098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594098.url(scheme.get, call_594098.host, call_594098.base,
                         call_594098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594098, url, valid)

proc call*(call_594099: Call_DeleteRepositoryPolicy_594086; body: JsonNode): Recallable =
  ## deleteRepositoryPolicy
  ## Deletes the repository policy from a specified repository.
  ##   body: JObject (required)
  var body_594100 = newJObject()
  if body != nil:
    body_594100 = body
  result = call_594099.call(nil, nil, nil, nil, body_594100)

var deleteRepositoryPolicy* = Call_DeleteRepositoryPolicy_594086(
    name: "deleteRepositoryPolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DeleteRepositoryPolicy",
    validator: validate_DeleteRepositoryPolicy_594087, base: "/",
    url: url_DeleteRepositoryPolicy_594088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImageScanFindings_594101 = ref object of OpenApiRestCall_593389
proc url_DescribeImageScanFindings_594103(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeImageScanFindings_594102(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the image scan findings for the specified image.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594104 = query.getOrDefault("nextToken")
  valid_594104 = validateParameter(valid_594104, JString, required = false,
                                 default = nil)
  if valid_594104 != nil:
    section.add "nextToken", valid_594104
  var valid_594105 = query.getOrDefault("maxResults")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "maxResults", valid_594105
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
  var valid_594106 = header.getOrDefault("X-Amz-Target")
  valid_594106 = validateParameter(valid_594106, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.DescribeImageScanFindings"))
  if valid_594106 != nil:
    section.add "X-Amz-Target", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Signature")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Signature", valid_594107
  var valid_594108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Content-Sha256", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Date")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Date", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Credential")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Credential", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Security-Token")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Security-Token", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Algorithm")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Algorithm", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-SignedHeaders", valid_594113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594115: Call_DescribeImageScanFindings_594101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the image scan findings for the specified image.
  ## 
  let valid = call_594115.validator(path, query, header, formData, body)
  let scheme = call_594115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594115.url(scheme.get, call_594115.host, call_594115.base,
                         call_594115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594115, url, valid)

proc call*(call_594116: Call_DescribeImageScanFindings_594101; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeImageScanFindings
  ## Describes the image scan findings for the specified image.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_594117 = newJObject()
  var body_594118 = newJObject()
  add(query_594117, "nextToken", newJString(nextToken))
  if body != nil:
    body_594118 = body
  add(query_594117, "maxResults", newJString(maxResults))
  result = call_594116.call(nil, query_594117, nil, nil, body_594118)

var describeImageScanFindings* = Call_DescribeImageScanFindings_594101(
    name: "describeImageScanFindings", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DescribeImageScanFindings",
    validator: validate_DescribeImageScanFindings_594102, base: "/",
    url: url_DescribeImageScanFindings_594103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeImages_594120 = ref object of OpenApiRestCall_593389
proc url_DescribeImages_594122(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeImages_594121(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns metadata about the images in a repository, including image size, image tags, and creation date.</p> <note> <p>Beginning with Docker version 1.9, the Docker client compresses image layers before pushing them to a V2 Docker registry. The output of the <code>docker images</code> command shows the uncompressed image size, so it may return a larger image size than the image sizes returned by <a>DescribeImages</a>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594123 = query.getOrDefault("nextToken")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "nextToken", valid_594123
  var valid_594124 = query.getOrDefault("maxResults")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "maxResults", valid_594124
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
      "AmazonEC2ContainerRegistry_V20150921.DescribeImages"))
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

proc call*(call_594134: Call_DescribeImages_594120; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns metadata about the images in a repository, including image size, image tags, and creation date.</p> <note> <p>Beginning with Docker version 1.9, the Docker client compresses image layers before pushing them to a V2 Docker registry. The output of the <code>docker images</code> command shows the uncompressed image size, so it may return a larger image size than the image sizes returned by <a>DescribeImages</a>.</p> </note>
  ## 
  let valid = call_594134.validator(path, query, header, formData, body)
  let scheme = call_594134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594134.url(scheme.get, call_594134.host, call_594134.base,
                         call_594134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594134, url, valid)

proc call*(call_594135: Call_DescribeImages_594120; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeImages
  ## <p>Returns metadata about the images in a repository, including image size, image tags, and creation date.</p> <note> <p>Beginning with Docker version 1.9, the Docker client compresses image layers before pushing them to a V2 Docker registry. The output of the <code>docker images</code> command shows the uncompressed image size, so it may return a larger image size than the image sizes returned by <a>DescribeImages</a>.</p> </note>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_594136 = newJObject()
  var body_594137 = newJObject()
  add(query_594136, "nextToken", newJString(nextToken))
  if body != nil:
    body_594137 = body
  add(query_594136, "maxResults", newJString(maxResults))
  result = call_594135.call(nil, query_594136, nil, nil, body_594137)

var describeImages* = Call_DescribeImages_594120(name: "describeImages",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DescribeImages",
    validator: validate_DescribeImages_594121, base: "/", url: url_DescribeImages_594122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRepositories_594138 = ref object of OpenApiRestCall_593389
proc url_DescribeRepositories_594140(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeRepositories_594139(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes image repositories in a registry.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594141 = query.getOrDefault("nextToken")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "nextToken", valid_594141
  var valid_594142 = query.getOrDefault("maxResults")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "maxResults", valid_594142
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
      "AmazonEC2ContainerRegistry_V20150921.DescribeRepositories"))
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

proc call*(call_594152: Call_DescribeRepositories_594138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes image repositories in a registry.
  ## 
  let valid = call_594152.validator(path, query, header, formData, body)
  let scheme = call_594152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594152.url(scheme.get, call_594152.host, call_594152.base,
                         call_594152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594152, url, valid)

proc call*(call_594153: Call_DescribeRepositories_594138; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## describeRepositories
  ## Describes image repositories in a registry.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_594154 = newJObject()
  var body_594155 = newJObject()
  add(query_594154, "nextToken", newJString(nextToken))
  if body != nil:
    body_594155 = body
  add(query_594154, "maxResults", newJString(maxResults))
  result = call_594153.call(nil, query_594154, nil, nil, body_594155)

var describeRepositories* = Call_DescribeRepositories_594138(
    name: "describeRepositories", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.DescribeRepositories",
    validator: validate_DescribeRepositories_594139, base: "/",
    url: url_DescribeRepositories_594140, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizationToken_594156 = ref object of OpenApiRestCall_593389
proc url_GetAuthorizationToken_594158(protocol: Scheme; host: string; base: string;
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

proc validate_GetAuthorizationToken_594157(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a token that is valid for a specified registry for 12 hours. This command allows you to use the <code>docker</code> CLI to push and pull images with Amazon ECR. If you do not specify a registry, the default registry is assumed.</p> <p>The <code>authorizationToken</code> returned for each registry specified is a base64 encoded string that can be decoded and used in a <code>docker login</code> command to authenticate to a registry. The AWS CLI offers an <code>aws ecr get-login</code> command that simplifies the login process.</p>
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
  valid_594159 = validateParameter(valid_594159, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetAuthorizationToken"))
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

proc call*(call_594168: Call_GetAuthorizationToken_594156; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a token that is valid for a specified registry for 12 hours. This command allows you to use the <code>docker</code> CLI to push and pull images with Amazon ECR. If you do not specify a registry, the default registry is assumed.</p> <p>The <code>authorizationToken</code> returned for each registry specified is a base64 encoded string that can be decoded and used in a <code>docker login</code> command to authenticate to a registry. The AWS CLI offers an <code>aws ecr get-login</code> command that simplifies the login process.</p>
  ## 
  let valid = call_594168.validator(path, query, header, formData, body)
  let scheme = call_594168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594168.url(scheme.get, call_594168.host, call_594168.base,
                         call_594168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594168, url, valid)

proc call*(call_594169: Call_GetAuthorizationToken_594156; body: JsonNode): Recallable =
  ## getAuthorizationToken
  ## <p>Retrieves a token that is valid for a specified registry for 12 hours. This command allows you to use the <code>docker</code> CLI to push and pull images with Amazon ECR. If you do not specify a registry, the default registry is assumed.</p> <p>The <code>authorizationToken</code> returned for each registry specified is a base64 encoded string that can be decoded and used in a <code>docker login</code> command to authenticate to a registry. The AWS CLI offers an <code>aws ecr get-login</code> command that simplifies the login process.</p>
  ##   body: JObject (required)
  var body_594170 = newJObject()
  if body != nil:
    body_594170 = body
  result = call_594169.call(nil, nil, nil, nil, body_594170)

var getAuthorizationToken* = Call_GetAuthorizationToken_594156(
    name: "getAuthorizationToken", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetAuthorizationToken",
    validator: validate_GetAuthorizationToken_594157, base: "/",
    url: url_GetAuthorizationToken_594158, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadUrlForLayer_594171 = ref object of OpenApiRestCall_593389
proc url_GetDownloadUrlForLayer_594173(protocol: Scheme; host: string; base: string;
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

proc validate_GetDownloadUrlForLayer_594172(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the pre-signed Amazon S3 download URL corresponding to an image layer. You can only get URLs for image layers that are referenced in an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
      "AmazonEC2ContainerRegistry_V20150921.GetDownloadUrlForLayer"))
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

proc call*(call_594183: Call_GetDownloadUrlForLayer_594171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the pre-signed Amazon S3 download URL corresponding to an image layer. You can only get URLs for image layers that are referenced in an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_594183.validator(path, query, header, formData, body)
  let scheme = call_594183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594183.url(scheme.get, call_594183.host, call_594183.base,
                         call_594183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594183, url, valid)

proc call*(call_594184: Call_GetDownloadUrlForLayer_594171; body: JsonNode): Recallable =
  ## getDownloadUrlForLayer
  ## <p>Retrieves the pre-signed Amazon S3 download URL corresponding to an image layer. You can only get URLs for image layers that are referenced in an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_594185 = newJObject()
  if body != nil:
    body_594185 = body
  result = call_594184.call(nil, nil, nil, nil, body_594185)

var getDownloadUrlForLayer* = Call_GetDownloadUrlForLayer_594171(
    name: "getDownloadUrlForLayer", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetDownloadUrlForLayer",
    validator: validate_GetDownloadUrlForLayer_594172, base: "/",
    url: url_GetDownloadUrlForLayer_594173, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicy_594186 = ref object of OpenApiRestCall_593389
proc url_GetLifecyclePolicy_594188(protocol: Scheme; host: string; base: string;
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

proc validate_GetLifecyclePolicy_594187(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves the specified lifecycle policy.
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
      "AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicy"))
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

proc call*(call_594198: Call_GetLifecyclePolicy_594186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the specified lifecycle policy.
  ## 
  let valid = call_594198.validator(path, query, header, formData, body)
  let scheme = call_594198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594198.url(scheme.get, call_594198.host, call_594198.base,
                         call_594198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594198, url, valid)

proc call*(call_594199: Call_GetLifecyclePolicy_594186; body: JsonNode): Recallable =
  ## getLifecyclePolicy
  ## Retrieves the specified lifecycle policy.
  ##   body: JObject (required)
  var body_594200 = newJObject()
  if body != nil:
    body_594200 = body
  result = call_594199.call(nil, nil, nil, nil, body_594200)

var getLifecyclePolicy* = Call_GetLifecyclePolicy_594186(
    name: "getLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicy",
    validator: validate_GetLifecyclePolicy_594187, base: "/",
    url: url_GetLifecyclePolicy_594188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLifecyclePolicyPreview_594201 = ref object of OpenApiRestCall_593389
proc url_GetLifecyclePolicyPreview_594203(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLifecyclePolicyPreview_594202(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the results of the specified lifecycle policy preview request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594204 = query.getOrDefault("nextToken")
  valid_594204 = validateParameter(valid_594204, JString, required = false,
                                 default = nil)
  if valid_594204 != nil:
    section.add "nextToken", valid_594204
  var valid_594205 = query.getOrDefault("maxResults")
  valid_594205 = validateParameter(valid_594205, JString, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "maxResults", valid_594205
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
  var valid_594206 = header.getOrDefault("X-Amz-Target")
  valid_594206 = validateParameter(valid_594206, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicyPreview"))
  if valid_594206 != nil:
    section.add "X-Amz-Target", valid_594206
  var valid_594207 = header.getOrDefault("X-Amz-Signature")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "X-Amz-Signature", valid_594207
  var valid_594208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "X-Amz-Content-Sha256", valid_594208
  var valid_594209 = header.getOrDefault("X-Amz-Date")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Date", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Credential")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Credential", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Security-Token")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Security-Token", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Algorithm")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Algorithm", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-SignedHeaders", valid_594213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594215: Call_GetLifecyclePolicyPreview_594201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the results of the specified lifecycle policy preview request.
  ## 
  let valid = call_594215.validator(path, query, header, formData, body)
  let scheme = call_594215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594215.url(scheme.get, call_594215.host, call_594215.base,
                         call_594215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594215, url, valid)

proc call*(call_594216: Call_GetLifecyclePolicyPreview_594201; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## getLifecyclePolicyPreview
  ## Retrieves the results of the specified lifecycle policy preview request.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_594217 = newJObject()
  var body_594218 = newJObject()
  add(query_594217, "nextToken", newJString(nextToken))
  if body != nil:
    body_594218 = body
  add(query_594217, "maxResults", newJString(maxResults))
  result = call_594216.call(nil, query_594217, nil, nil, body_594218)

var getLifecyclePolicyPreview* = Call_GetLifecyclePolicyPreview_594201(
    name: "getLifecyclePolicyPreview", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetLifecyclePolicyPreview",
    validator: validate_GetLifecyclePolicyPreview_594202, base: "/",
    url: url_GetLifecyclePolicyPreview_594203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRepositoryPolicy_594219 = ref object of OpenApiRestCall_593389
proc url_GetRepositoryPolicy_594221(protocol: Scheme; host: string; base: string;
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

proc validate_GetRepositoryPolicy_594220(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves the repository policy for a specified repository.
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
  var valid_594222 = header.getOrDefault("X-Amz-Target")
  valid_594222 = validateParameter(valid_594222, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.GetRepositoryPolicy"))
  if valid_594222 != nil:
    section.add "X-Amz-Target", valid_594222
  var valid_594223 = header.getOrDefault("X-Amz-Signature")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "X-Amz-Signature", valid_594223
  var valid_594224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "X-Amz-Content-Sha256", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Date")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Date", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Credential")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Credential", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Security-Token")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Security-Token", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-Algorithm")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-Algorithm", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-SignedHeaders", valid_594229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594231: Call_GetRepositoryPolicy_594219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the repository policy for a specified repository.
  ## 
  let valid = call_594231.validator(path, query, header, formData, body)
  let scheme = call_594231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594231.url(scheme.get, call_594231.host, call_594231.base,
                         call_594231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594231, url, valid)

proc call*(call_594232: Call_GetRepositoryPolicy_594219; body: JsonNode): Recallable =
  ## getRepositoryPolicy
  ## Retrieves the repository policy for a specified repository.
  ##   body: JObject (required)
  var body_594233 = newJObject()
  if body != nil:
    body_594233 = body
  result = call_594232.call(nil, nil, nil, nil, body_594233)

var getRepositoryPolicy* = Call_GetRepositoryPolicy_594219(
    name: "getRepositoryPolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.GetRepositoryPolicy",
    validator: validate_GetRepositoryPolicy_594220, base: "/",
    url: url_GetRepositoryPolicy_594221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_InitiateLayerUpload_594234 = ref object of OpenApiRestCall_593389
proc url_InitiateLayerUpload_594236(protocol: Scheme; host: string; base: string;
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

proc validate_InitiateLayerUpload_594235(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Notify Amazon ECR that you intend to upload an image layer.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
  var valid_594237 = header.getOrDefault("X-Amz-Target")
  valid_594237 = validateParameter(valid_594237, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.InitiateLayerUpload"))
  if valid_594237 != nil:
    section.add "X-Amz-Target", valid_594237
  var valid_594238 = header.getOrDefault("X-Amz-Signature")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "X-Amz-Signature", valid_594238
  var valid_594239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Content-Sha256", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Date")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Date", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-Credential")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Credential", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Security-Token")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Security-Token", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-Algorithm")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Algorithm", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-SignedHeaders", valid_594244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594246: Call_InitiateLayerUpload_594234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Notify Amazon ECR that you intend to upload an image layer.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_594246.validator(path, query, header, formData, body)
  let scheme = call_594246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594246.url(scheme.get, call_594246.host, call_594246.base,
                         call_594246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594246, url, valid)

proc call*(call_594247: Call_InitiateLayerUpload_594234; body: JsonNode): Recallable =
  ## initiateLayerUpload
  ## <p>Notify Amazon ECR that you intend to upload an image layer.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_594248 = newJObject()
  if body != nil:
    body_594248 = body
  result = call_594247.call(nil, nil, nil, nil, body_594248)

var initiateLayerUpload* = Call_InitiateLayerUpload_594234(
    name: "initiateLayerUpload", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.InitiateLayerUpload",
    validator: validate_InitiateLayerUpload_594235, base: "/",
    url: url_InitiateLayerUpload_594236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListImages_594249 = ref object of OpenApiRestCall_593389
proc url_ListImages_594251(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListImages_594250(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all the image IDs for a given repository.</p> <p>You can filter images based on whether or not they are tagged by setting the <code>tagStatus</code> parameter to <code>TAGGED</code> or <code>UNTAGGED</code>. For example, you can filter your results to return only <code>UNTAGGED</code> images and then pipe that result to a <a>BatchDeleteImage</a> operation to delete them. Or, you can filter your results to return only <code>TAGGED</code> images to list all of the tags in your repository.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_594252 = query.getOrDefault("nextToken")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "nextToken", valid_594252
  var valid_594253 = query.getOrDefault("maxResults")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "maxResults", valid_594253
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
  var valid_594254 = header.getOrDefault("X-Amz-Target")
  valid_594254 = validateParameter(valid_594254, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.ListImages"))
  if valid_594254 != nil:
    section.add "X-Amz-Target", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Signature")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Signature", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Content-Sha256", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Date")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Date", valid_594257
  var valid_594258 = header.getOrDefault("X-Amz-Credential")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "X-Amz-Credential", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Security-Token")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Security-Token", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Algorithm")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Algorithm", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-SignedHeaders", valid_594261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594263: Call_ListImages_594249; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the image IDs for a given repository.</p> <p>You can filter images based on whether or not they are tagged by setting the <code>tagStatus</code> parameter to <code>TAGGED</code> or <code>UNTAGGED</code>. For example, you can filter your results to return only <code>UNTAGGED</code> images and then pipe that result to a <a>BatchDeleteImage</a> operation to delete them. Or, you can filter your results to return only <code>TAGGED</code> images to list all of the tags in your repository.</p>
  ## 
  let valid = call_594263.validator(path, query, header, formData, body)
  let scheme = call_594263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594263.url(scheme.get, call_594263.host, call_594263.base,
                         call_594263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594263, url, valid)

proc call*(call_594264: Call_ListImages_594249; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listImages
  ## <p>Lists all the image IDs for a given repository.</p> <p>You can filter images based on whether or not they are tagged by setting the <code>tagStatus</code> parameter to <code>TAGGED</code> or <code>UNTAGGED</code>. For example, you can filter your results to return only <code>UNTAGGED</code> images and then pipe that result to a <a>BatchDeleteImage</a> operation to delete them. Or, you can filter your results to return only <code>TAGGED</code> images to list all of the tags in your repository.</p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_594265 = newJObject()
  var body_594266 = newJObject()
  add(query_594265, "nextToken", newJString(nextToken))
  if body != nil:
    body_594266 = body
  add(query_594265, "maxResults", newJString(maxResults))
  result = call_594264.call(nil, query_594265, nil, nil, body_594266)

var listImages* = Call_ListImages_594249(name: "listImages",
                                      meth: HttpMethod.HttpPost,
                                      host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.ListImages",
                                      validator: validate_ListImages_594250,
                                      base: "/", url: url_ListImages_594251,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594267 = ref object of OpenApiRestCall_593389
proc url_ListTagsForResource_594269(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_594268(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## List the tags for an Amazon ECR resource.
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
  var valid_594270 = header.getOrDefault("X-Amz-Target")
  valid_594270 = validateParameter(valid_594270, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.ListTagsForResource"))
  if valid_594270 != nil:
    section.add "X-Amz-Target", valid_594270
  var valid_594271 = header.getOrDefault("X-Amz-Signature")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Signature", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Content-Sha256", valid_594272
  var valid_594273 = header.getOrDefault("X-Amz-Date")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "X-Amz-Date", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Credential")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Credential", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Security-Token")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Security-Token", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-Algorithm")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-Algorithm", valid_594276
  var valid_594277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-SignedHeaders", valid_594277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594279: Call_ListTagsForResource_594267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an Amazon ECR resource.
  ## 
  let valid = call_594279.validator(path, query, header, formData, body)
  let scheme = call_594279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594279.url(scheme.get, call_594279.host, call_594279.base,
                         call_594279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594279, url, valid)

proc call*(call_594280: Call_ListTagsForResource_594267; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for an Amazon ECR resource.
  ##   body: JObject (required)
  var body_594281 = newJObject()
  if body != nil:
    body_594281 = body
  result = call_594280.call(nil, nil, nil, nil, body_594281)

var listTagsForResource* = Call_ListTagsForResource_594267(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.ListTagsForResource",
    validator: validate_ListTagsForResource_594268, base: "/",
    url: url_ListTagsForResource_594269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImage_594282 = ref object of OpenApiRestCall_593389
proc url_PutImage_594284(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutImage_594283(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates or updates the image manifest and tags associated with an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
  var valid_594285 = header.getOrDefault("X-Amz-Target")
  valid_594285 = validateParameter(valid_594285, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutImage"))
  if valid_594285 != nil:
    section.add "X-Amz-Target", valid_594285
  var valid_594286 = header.getOrDefault("X-Amz-Signature")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Signature", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Content-Sha256", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Date")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Date", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Credential")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Credential", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Security-Token")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Security-Token", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Algorithm")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Algorithm", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-SignedHeaders", valid_594292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594294: Call_PutImage_594282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates or updates the image manifest and tags associated with an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_594294.validator(path, query, header, formData, body)
  let scheme = call_594294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594294.url(scheme.get, call_594294.host, call_594294.base,
                         call_594294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594294, url, valid)

proc call*(call_594295: Call_PutImage_594282; body: JsonNode): Recallable =
  ## putImage
  ## <p>Creates or updates the image manifest and tags associated with an image.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_594296 = newJObject()
  if body != nil:
    body_594296 = body
  result = call_594295.call(nil, nil, nil, nil, body_594296)

var putImage* = Call_PutImage_594282(name: "putImage", meth: HttpMethod.HttpPost,
                                  host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutImage",
                                  validator: validate_PutImage_594283, base: "/",
                                  url: url_PutImage_594284,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImageScanningConfiguration_594297 = ref object of OpenApiRestCall_593389
proc url_PutImageScanningConfiguration_594299(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutImageScanningConfiguration_594298(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the image scanning configuration for a repository.
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
  var valid_594300 = header.getOrDefault("X-Amz-Target")
  valid_594300 = validateParameter(valid_594300, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutImageScanningConfiguration"))
  if valid_594300 != nil:
    section.add "X-Amz-Target", valid_594300
  var valid_594301 = header.getOrDefault("X-Amz-Signature")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Signature", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Content-Sha256", valid_594302
  var valid_594303 = header.getOrDefault("X-Amz-Date")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Date", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Credential")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Credential", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Security-Token")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Security-Token", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Algorithm")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Algorithm", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-SignedHeaders", valid_594307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594309: Call_PutImageScanningConfiguration_594297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the image scanning configuration for a repository.
  ## 
  let valid = call_594309.validator(path, query, header, formData, body)
  let scheme = call_594309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594309.url(scheme.get, call_594309.host, call_594309.base,
                         call_594309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594309, url, valid)

proc call*(call_594310: Call_PutImageScanningConfiguration_594297; body: JsonNode): Recallable =
  ## putImageScanningConfiguration
  ## Updates the image scanning configuration for a repository.
  ##   body: JObject (required)
  var body_594311 = newJObject()
  if body != nil:
    body_594311 = body
  result = call_594310.call(nil, nil, nil, nil, body_594311)

var putImageScanningConfiguration* = Call_PutImageScanningConfiguration_594297(
    name: "putImageScanningConfiguration", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutImageScanningConfiguration",
    validator: validate_PutImageScanningConfiguration_594298, base: "/",
    url: url_PutImageScanningConfiguration_594299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutImageTagMutability_594312 = ref object of OpenApiRestCall_593389
proc url_PutImageTagMutability_594314(protocol: Scheme; host: string; base: string;
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

proc validate_PutImageTagMutability_594313(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the image tag mutability settings for a repository. When a repository is configured with tag immutability, all image tags within the repository will be prevented them from being overwritten. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-tag-mutability.html">Image Tag Mutability</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
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
  var valid_594315 = header.getOrDefault("X-Amz-Target")
  valid_594315 = validateParameter(valid_594315, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutImageTagMutability"))
  if valid_594315 != nil:
    section.add "X-Amz-Target", valid_594315
  var valid_594316 = header.getOrDefault("X-Amz-Signature")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "X-Amz-Signature", valid_594316
  var valid_594317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "X-Amz-Content-Sha256", valid_594317
  var valid_594318 = header.getOrDefault("X-Amz-Date")
  valid_594318 = validateParameter(valid_594318, JString, required = false,
                                 default = nil)
  if valid_594318 != nil:
    section.add "X-Amz-Date", valid_594318
  var valid_594319 = header.getOrDefault("X-Amz-Credential")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Credential", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-Security-Token")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-Security-Token", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-Algorithm")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Algorithm", valid_594321
  var valid_594322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "X-Amz-SignedHeaders", valid_594322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594324: Call_PutImageTagMutability_594312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the image tag mutability settings for a repository. When a repository is configured with tag immutability, all image tags within the repository will be prevented them from being overwritten. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-tag-mutability.html">Image Tag Mutability</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ## 
  let valid = call_594324.validator(path, query, header, formData, body)
  let scheme = call_594324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594324.url(scheme.get, call_594324.host, call_594324.base,
                         call_594324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594324, url, valid)

proc call*(call_594325: Call_PutImageTagMutability_594312; body: JsonNode): Recallable =
  ## putImageTagMutability
  ## Updates the image tag mutability settings for a repository. When a repository is configured with tag immutability, all image tags within the repository will be prevented them from being overwritten. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-tag-mutability.html">Image Tag Mutability</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ##   body: JObject (required)
  var body_594326 = newJObject()
  if body != nil:
    body_594326 = body
  result = call_594325.call(nil, nil, nil, nil, body_594326)

var putImageTagMutability* = Call_PutImageTagMutability_594312(
    name: "putImageTagMutability", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutImageTagMutability",
    validator: validate_PutImageTagMutability_594313, base: "/",
    url: url_PutImageTagMutability_594314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLifecyclePolicy_594327 = ref object of OpenApiRestCall_593389
proc url_PutLifecyclePolicy_594329(protocol: Scheme; host: string; base: string;
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

proc validate_PutLifecyclePolicy_594328(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Creates or updates a lifecycle policy. For information about lifecycle policy syntax, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html">Lifecycle Policy Template</a>.
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
  var valid_594330 = header.getOrDefault("X-Amz-Target")
  valid_594330 = validateParameter(valid_594330, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.PutLifecyclePolicy"))
  if valid_594330 != nil:
    section.add "X-Amz-Target", valid_594330
  var valid_594331 = header.getOrDefault("X-Amz-Signature")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-Signature", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Content-Sha256", valid_594332
  var valid_594333 = header.getOrDefault("X-Amz-Date")
  valid_594333 = validateParameter(valid_594333, JString, required = false,
                                 default = nil)
  if valid_594333 != nil:
    section.add "X-Amz-Date", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-Credential")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Credential", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-Security-Token")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-Security-Token", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Algorithm")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Algorithm", valid_594336
  var valid_594337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-SignedHeaders", valid_594337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594339: Call_PutLifecyclePolicy_594327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates a lifecycle policy. For information about lifecycle policy syntax, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html">Lifecycle Policy Template</a>.
  ## 
  let valid = call_594339.validator(path, query, header, formData, body)
  let scheme = call_594339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594339.url(scheme.get, call_594339.host, call_594339.base,
                         call_594339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594339, url, valid)

proc call*(call_594340: Call_PutLifecyclePolicy_594327; body: JsonNode): Recallable =
  ## putLifecyclePolicy
  ## Creates or updates a lifecycle policy. For information about lifecycle policy syntax, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html">Lifecycle Policy Template</a>.
  ##   body: JObject (required)
  var body_594341 = newJObject()
  if body != nil:
    body_594341 = body
  result = call_594340.call(nil, nil, nil, nil, body_594341)

var putLifecyclePolicy* = Call_PutLifecyclePolicy_594327(
    name: "putLifecyclePolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.PutLifecyclePolicy",
    validator: validate_PutLifecyclePolicy_594328, base: "/",
    url: url_PutLifecyclePolicy_594329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetRepositoryPolicy_594342 = ref object of OpenApiRestCall_593389
proc url_SetRepositoryPolicy_594344(protocol: Scheme; host: string; base: string;
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

proc validate_SetRepositoryPolicy_594343(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Applies a repository policy on a specified repository to control access permissions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/RepositoryPolicies.html">Amazon ECR Repository Policies</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
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
  var valid_594345 = header.getOrDefault("X-Amz-Target")
  valid_594345 = validateParameter(valid_594345, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.SetRepositoryPolicy"))
  if valid_594345 != nil:
    section.add "X-Amz-Target", valid_594345
  var valid_594346 = header.getOrDefault("X-Amz-Signature")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Signature", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Content-Sha256", valid_594347
  var valid_594348 = header.getOrDefault("X-Amz-Date")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "X-Amz-Date", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Credential")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Credential", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-Security-Token")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Security-Token", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-Algorithm")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-Algorithm", valid_594351
  var valid_594352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-SignedHeaders", valid_594352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594354: Call_SetRepositoryPolicy_594342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Applies a repository policy on a specified repository to control access permissions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/RepositoryPolicies.html">Amazon ECR Repository Policies</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ## 
  let valid = call_594354.validator(path, query, header, formData, body)
  let scheme = call_594354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594354.url(scheme.get, call_594354.host, call_594354.base,
                         call_594354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594354, url, valid)

proc call*(call_594355: Call_SetRepositoryPolicy_594342; body: JsonNode): Recallable =
  ## setRepositoryPolicy
  ## Applies a repository policy on a specified repository to control access permissions. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/RepositoryPolicies.html">Amazon ECR Repository Policies</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ##   body: JObject (required)
  var body_594356 = newJObject()
  if body != nil:
    body_594356 = body
  result = call_594355.call(nil, nil, nil, nil, body_594356)

var setRepositoryPolicy* = Call_SetRepositoryPolicy_594342(
    name: "setRepositoryPolicy", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.SetRepositoryPolicy",
    validator: validate_SetRepositoryPolicy_594343, base: "/",
    url: url_SetRepositoryPolicy_594344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImageScan_594357 = ref object of OpenApiRestCall_593389
proc url_StartImageScan_594359(protocol: Scheme; host: string; base: string;
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

proc validate_StartImageScan_594358(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Starts an image vulnerability scan. An image scan can only be started once per day on an individual image. This limit includes if an image was scanned on initial push. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html">Image Scanning</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
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
  var valid_594360 = header.getOrDefault("X-Amz-Target")
  valid_594360 = validateParameter(valid_594360, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.StartImageScan"))
  if valid_594360 != nil:
    section.add "X-Amz-Target", valid_594360
  var valid_594361 = header.getOrDefault("X-Amz-Signature")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "X-Amz-Signature", valid_594361
  var valid_594362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "X-Amz-Content-Sha256", valid_594362
  var valid_594363 = header.getOrDefault("X-Amz-Date")
  valid_594363 = validateParameter(valid_594363, JString, required = false,
                                 default = nil)
  if valid_594363 != nil:
    section.add "X-Amz-Date", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-Credential")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Credential", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-Security-Token")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Security-Token", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Algorithm")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Algorithm", valid_594366
  var valid_594367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-SignedHeaders", valid_594367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594369: Call_StartImageScan_594357; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an image vulnerability scan. An image scan can only be started once per day on an individual image. This limit includes if an image was scanned on initial push. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html">Image Scanning</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ## 
  let valid = call_594369.validator(path, query, header, formData, body)
  let scheme = call_594369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594369.url(scheme.get, call_594369.host, call_594369.base,
                         call_594369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594369, url, valid)

proc call*(call_594370: Call_StartImageScan_594357; body: JsonNode): Recallable =
  ## startImageScan
  ## Starts an image vulnerability scan. An image scan can only be started once per day on an individual image. This limit includes if an image was scanned on initial push. For more information, see <a href="https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html">Image Scanning</a> in the <i>Amazon Elastic Container Registry User Guide</i>.
  ##   body: JObject (required)
  var body_594371 = newJObject()
  if body != nil:
    body_594371 = body
  result = call_594370.call(nil, nil, nil, nil, body_594371)

var startImageScan* = Call_StartImageScan_594357(name: "startImageScan",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.StartImageScan",
    validator: validate_StartImageScan_594358, base: "/", url: url_StartImageScan_594359,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartLifecyclePolicyPreview_594372 = ref object of OpenApiRestCall_593389
proc url_StartLifecyclePolicyPreview_594374(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartLifecyclePolicyPreview_594373(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts a preview of the specified lifecycle policy. This allows you to see the results before creating the lifecycle policy.
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
  var valid_594375 = header.getOrDefault("X-Amz-Target")
  valid_594375 = validateParameter(valid_594375, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.StartLifecyclePolicyPreview"))
  if valid_594375 != nil:
    section.add "X-Amz-Target", valid_594375
  var valid_594376 = header.getOrDefault("X-Amz-Signature")
  valid_594376 = validateParameter(valid_594376, JString, required = false,
                                 default = nil)
  if valid_594376 != nil:
    section.add "X-Amz-Signature", valid_594376
  var valid_594377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "X-Amz-Content-Sha256", valid_594377
  var valid_594378 = header.getOrDefault("X-Amz-Date")
  valid_594378 = validateParameter(valid_594378, JString, required = false,
                                 default = nil)
  if valid_594378 != nil:
    section.add "X-Amz-Date", valid_594378
  var valid_594379 = header.getOrDefault("X-Amz-Credential")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Credential", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Security-Token")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Security-Token", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Algorithm")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Algorithm", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-SignedHeaders", valid_594382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594384: Call_StartLifecyclePolicyPreview_594372; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a preview of the specified lifecycle policy. This allows you to see the results before creating the lifecycle policy.
  ## 
  let valid = call_594384.validator(path, query, header, formData, body)
  let scheme = call_594384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594384.url(scheme.get, call_594384.host, call_594384.base,
                         call_594384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594384, url, valid)

proc call*(call_594385: Call_StartLifecyclePolicyPreview_594372; body: JsonNode): Recallable =
  ## startLifecyclePolicyPreview
  ## Starts a preview of the specified lifecycle policy. This allows you to see the results before creating the lifecycle policy.
  ##   body: JObject (required)
  var body_594386 = newJObject()
  if body != nil:
    body_594386 = body
  result = call_594385.call(nil, nil, nil, nil, body_594386)

var startLifecyclePolicyPreview* = Call_StartLifecyclePolicyPreview_594372(
    name: "startLifecyclePolicyPreview", meth: HttpMethod.HttpPost,
    host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.StartLifecyclePolicyPreview",
    validator: validate_StartLifecyclePolicyPreview_594373, base: "/",
    url: url_StartLifecyclePolicyPreview_594374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594387 = ref object of OpenApiRestCall_593389
proc url_TagResource_594389(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_594388(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds specified tags to a resource with the specified ARN. Existing tags on a resource are not changed if they are not specified in the request parameters.
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
  var valid_594390 = header.getOrDefault("X-Amz-Target")
  valid_594390 = validateParameter(valid_594390, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.TagResource"))
  if valid_594390 != nil:
    section.add "X-Amz-Target", valid_594390
  var valid_594391 = header.getOrDefault("X-Amz-Signature")
  valid_594391 = validateParameter(valid_594391, JString, required = false,
                                 default = nil)
  if valid_594391 != nil:
    section.add "X-Amz-Signature", valid_594391
  var valid_594392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "X-Amz-Content-Sha256", valid_594392
  var valid_594393 = header.getOrDefault("X-Amz-Date")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "X-Amz-Date", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Credential")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Credential", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Security-Token")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Security-Token", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Algorithm")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Algorithm", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-SignedHeaders", valid_594397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594399: Call_TagResource_594387; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds specified tags to a resource with the specified ARN. Existing tags on a resource are not changed if they are not specified in the request parameters.
  ## 
  let valid = call_594399.validator(path, query, header, formData, body)
  let scheme = call_594399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594399.url(scheme.get, call_594399.host, call_594399.base,
                         call_594399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594399, url, valid)

proc call*(call_594400: Call_TagResource_594387; body: JsonNode): Recallable =
  ## tagResource
  ## Adds specified tags to a resource with the specified ARN. Existing tags on a resource are not changed if they are not specified in the request parameters.
  ##   body: JObject (required)
  var body_594401 = newJObject()
  if body != nil:
    body_594401 = body
  result = call_594400.call(nil, nil, nil, nil, body_594401)

var tagResource* = Call_TagResource_594387(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.TagResource",
                                        validator: validate_TagResource_594388,
                                        base: "/", url: url_TagResource_594389,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594402 = ref object of OpenApiRestCall_593389
proc url_UntagResource_594404(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_594403(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes specified tags from a resource.
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
  var valid_594405 = header.getOrDefault("X-Amz-Target")
  valid_594405 = validateParameter(valid_594405, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.UntagResource"))
  if valid_594405 != nil:
    section.add "X-Amz-Target", valid_594405
  var valid_594406 = header.getOrDefault("X-Amz-Signature")
  valid_594406 = validateParameter(valid_594406, JString, required = false,
                                 default = nil)
  if valid_594406 != nil:
    section.add "X-Amz-Signature", valid_594406
  var valid_594407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594407 = validateParameter(valid_594407, JString, required = false,
                                 default = nil)
  if valid_594407 != nil:
    section.add "X-Amz-Content-Sha256", valid_594407
  var valid_594408 = header.getOrDefault("X-Amz-Date")
  valid_594408 = validateParameter(valid_594408, JString, required = false,
                                 default = nil)
  if valid_594408 != nil:
    section.add "X-Amz-Date", valid_594408
  var valid_594409 = header.getOrDefault("X-Amz-Credential")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "X-Amz-Credential", valid_594409
  var valid_594410 = header.getOrDefault("X-Amz-Security-Token")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "X-Amz-Security-Token", valid_594410
  var valid_594411 = header.getOrDefault("X-Amz-Algorithm")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Algorithm", valid_594411
  var valid_594412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-SignedHeaders", valid_594412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594414: Call_UntagResource_594402; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_594414.validator(path, query, header, formData, body)
  let scheme = call_594414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594414.url(scheme.get, call_594414.host, call_594414.base,
                         call_594414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594414, url, valid)

proc call*(call_594415: Call_UntagResource_594402; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   body: JObject (required)
  var body_594416 = newJObject()
  if body != nil:
    body_594416 = body
  result = call_594415.call(nil, nil, nil, nil, body_594416)

var untagResource* = Call_UntagResource_594402(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com",
    route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.UntagResource",
    validator: validate_UntagResource_594403, base: "/", url: url_UntagResource_594404,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UploadLayerPart_594417 = ref object of OpenApiRestCall_593389
proc url_UploadLayerPart_594419(protocol: Scheme; host: string; base: string;
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

proc validate_UploadLayerPart_594418(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Uploads an image layer part to Amazon ECR.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
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
  var valid_594420 = header.getOrDefault("X-Amz-Target")
  valid_594420 = validateParameter(valid_594420, JString, required = true, default = newJString(
      "AmazonEC2ContainerRegistry_V20150921.UploadLayerPart"))
  if valid_594420 != nil:
    section.add "X-Amz-Target", valid_594420
  var valid_594421 = header.getOrDefault("X-Amz-Signature")
  valid_594421 = validateParameter(valid_594421, JString, required = false,
                                 default = nil)
  if valid_594421 != nil:
    section.add "X-Amz-Signature", valid_594421
  var valid_594422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594422 = validateParameter(valid_594422, JString, required = false,
                                 default = nil)
  if valid_594422 != nil:
    section.add "X-Amz-Content-Sha256", valid_594422
  var valid_594423 = header.getOrDefault("X-Amz-Date")
  valid_594423 = validateParameter(valid_594423, JString, required = false,
                                 default = nil)
  if valid_594423 != nil:
    section.add "X-Amz-Date", valid_594423
  var valid_594424 = header.getOrDefault("X-Amz-Credential")
  valid_594424 = validateParameter(valid_594424, JString, required = false,
                                 default = nil)
  if valid_594424 != nil:
    section.add "X-Amz-Credential", valid_594424
  var valid_594425 = header.getOrDefault("X-Amz-Security-Token")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Security-Token", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Algorithm")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Algorithm", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-SignedHeaders", valid_594427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594429: Call_UploadLayerPart_594417; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uploads an image layer part to Amazon ECR.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ## 
  let valid = call_594429.validator(path, query, header, formData, body)
  let scheme = call_594429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594429.url(scheme.get, call_594429.host, call_594429.base,
                         call_594429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594429, url, valid)

proc call*(call_594430: Call_UploadLayerPart_594417; body: JsonNode): Recallable =
  ## uploadLayerPart
  ## <p>Uploads an image layer part to Amazon ECR.</p> <note> <p>This operation is used by the Amazon ECR proxy, and it is not intended for general use by customers for pulling and pushing images. In most cases, you should use the <code>docker</code> CLI to pull, tag, and push images.</p> </note>
  ##   body: JObject (required)
  var body_594431 = newJObject()
  if body != nil:
    body_594431 = body
  result = call_594430.call(nil, nil, nil, nil, body_594431)

var uploadLayerPart* = Call_UploadLayerPart_594417(name: "uploadLayerPart",
    meth: HttpMethod.HttpPost, host: "api.ecr.amazonaws.com", route: "/#X-Amz-Target=AmazonEC2ContainerRegistry_V20150921.UploadLayerPart",
    validator: validate_UploadLayerPart_594418, base: "/", url: url_UploadLayerPart_594419,
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
